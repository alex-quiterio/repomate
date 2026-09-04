# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Sync command for syncing repositories in parallel
      class Sync < Base
        def execute
          repos_to_sync = optionally_filter_repositories_by_pattern(store.all)
          return puts 'No repositories to sync' if repos_to_sync.empty?

          puts "\e[34mSyncing #{repos_to_sync.length} repositories...\e[0m"

          failures = sync_in_parallel(repos_to_sync)

          puts "\e[34mSync complete ✨\e[0m" if failures.zero?
          puts "\e[33mSync complete with #{failures} failed repositories\e[0m" unless failures.zero?
        end

        private

        def optionally_filter_repositories_by_pattern(repositories)
          return repositories unless config.pattern

          repositories.select { |repo| repo.url.include?(config.pattern) }
        end

        # Hands the repositories to a pool of workers, each pulling the next one
        # off the queue as soon as it is free. Every repository in flight gets
        # its own progress bar, and prints a final line once it is done.
        def sync_in_parallel(repositories)
          queue = queue_of(repositories)
          progress = progress_for(repositories)
          failures = Queue.new

          progress.start
          workers(jobs_count(repositories.length)) do
            while (repository = queue.pop)
              result = sync_with_progress(repository, progress)
              failures << result unless result.success?
            end
          end
          failures.size
        ensure
          progress&.stop
        end

        def queue_of(repositories)
          Queue.new.tap do |queue|
            repositories.each { |repository| queue << repository }
            queue.close
          end
        end

        def progress_for(repositories)
          Interface::Progress.build(repositories.map(&:name))
        end

        def workers(count, &block)
          Array.new(count) { Thread.new(&block) }.each(&:join)
        end

        def jobs_count(total)
          [config.jobs, total].min
        end

        def sync_with_progress(repository, progress)
          progress.begin(repository.name)
          result = sync_repository(repository) do |fraction, label|
            progress.update(repository.name, fraction, label)
          end
          progress.finish(repository.name, result)
          result
        end

        def sync_repository(repository, &progress)
          return clone_repository(repository, &progress) unless repository.exists_locally?

          if Infra::Git::Operations.update(repository, &progress)
            Domain::Result.success("\e[32m♲ #{repository.name} updated 🎉\e[0m")
          else
            Domain::Result.success("\e[36m♲ #{repository.name} no changes to pull\e[0m")
          end
        rescue Infra::Git::Operations::Error => e
          Domain::Result.failure("\e[31m✗ #{repository.name}: #{e.message}\e[0m")
        end

        def clone_repository(repository, &progress)
          Infra::Git::Operations.clone(repository, &progress)

          Domain::Result.success("\e[32m⬇ #{repository.name} cloned 🎉\e[0m")
        end
      end
    end
  end
end
