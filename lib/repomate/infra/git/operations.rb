# frozen_string_literal: true

module Repomate
  module Infra
    module Git
      # Contains operations for working with Git repositories.
      #
      # Every command runs in its own process against an explicit path instead
      # of changing the working directory, so these operations are safe to call
      # concurrently from several threads.
      #
      # The long running commands accept a progress block that receives
      # (fraction, label) as git reports its own percentages.
      class Operations
        class Error < StandardError; end

        BUFFER_SIZE = 4096

        def self.update(repository, &progress)
          path = repository.path

          track(path, 'git fetch --all --progress', 0.0..0.4, 'fetching', progress)
          run(path, 'git reset')
          stashed = run(path, 'git stash save --keep-index --include-untracked')

          pulled = pull(path, progress)

          run(path, 'git stash pop') if stashed
          report(progress, 1.0, pulled ? 'updated' : 'no changes')
          pulled
        rescue StandardError => e
          raise Error, "Failed to update repository: #{e.message}"
        end

        def self.clone(repository, &progress)
          command = "git clone --progress #{repository.url} #{repository.path}"
          success = track(nil, command, 0.0..1.0, 'cloning', progress)

          raise Error, 'Failed to clone repository' unless success
        end

        def self.remove(repository)
          FileUtils.rm_rf(repository.path)

          raise Error, 'Failed to remove repository' if repository.exists_locally?
        end

        def self.pull(path, progress = nil)
          default_branch = default_branch(path)
          current_branch = capture(path, 'git rev-parse --abbrev-ref HEAD')
          command = "git pull --progress origin #{default_branch}"

          return track(path, command, 0.4..0.95, 'pulling', progress) if default_branch == current_branch

          run(path, "git checkout #{default_branch}")
          pulled = track(path, command, 0.4..0.9, 'pulling', progress)
          run(path, "git checkout #{current_branch}")
          pulled
        end

        def self.default_branch(path)
          run(path, 'grep -q main .git/config') ? 'main' : 'master'
        end

        # Runs a command and turns the percentages git prints along the way into
        # a fraction of the slice of the whole operation that it covers.
        def self.track(path, command, slice, label, progress)
          return run(path, command) unless progress

          report(progress, slice.first, label)
          stream(path, command) do |line|
            percent = line[/(\d+)%/, 1]
            next unless percent

            report(progress, slice.first + ((slice.last - slice.first) * (percent.to_i / 100.0)), label)
          end
        end

        def self.report(progress, fraction, label)
          progress&.call(fraction, label)
        end

        # Runs a command inside the repository without touching the working
        # directory of the current process.
        def self.run(path, command)
          system(command, **spawn_options(path).merge(out: File::NULL, err: File::NULL))
        end

        def self.stream(path, command, &on_line)
          Open3.popen2e(command, **spawn_options(path)) do |input, output, wait|
            input.close
            read_lines(output, &on_line)
            wait.value.success?
          end
        end

        # git separates progress updates with carriage returns rather than
        # newlines, so the stream is split on both.
        def self.read_lines(output)
          buffer = +''

          until output.eof?
            buffer << output.readpartial(BUFFER_SIZE)
            yield(buffer.slice!(0..buffer.index(/[\r\n]/)).strip) while buffer.match?(/[\r\n]/)
          end
        rescue IOError
          nil
        end

        def self.capture(path, command)
          IO.popen(command, **spawn_options(path), err: File::NULL, &:read).to_s.strip
        end

        def self.spawn_options(path)
          path ? { chdir: path } : {}
        end

        private_class_method :pull, :default_branch, :track, :report, :run,
                             :stream, :read_lines, :capture, :spawn_options
      end
    end
  end
end
