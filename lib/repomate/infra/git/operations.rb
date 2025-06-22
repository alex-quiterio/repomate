# frozen_string_literal: true

module Repomate
  module Infra
    module Git
      # Contains operations for working with Git repositories
      class Operations
        class Error < StandardError; end

        def self.update(repository)
          Dir.chdir(repository.path) do
            success = true
            system('git reset', out: File::NULL, err: File::NULL)
            stashed = system('git stash save --keep-index --include-untracked', out: File::NULL)
            default_branch = system('cat .git/config | grep "main"', out: File::NULL) ? 'main' : 'master'
            current_branch = `git rev-parse --abbrev-ref HEAD`.strip

            if default_branch != current_branch
              success &&= system(`git checkout #{default_branch}`, out: File::NULL, err: File::NULL)
              success &&= system('git pull', out: File::NULL)
              success &&= system(`git checkout -`, out: File::NULL)
            else
              success &&= system('git pull', out: File::NULL)
            end

            system('git stash pop', out: File::NULL, err: File::NULL) if stashed

            raise Error, 'Failed to update repository' unless success

            puts "\e[32mDONE 🎉\e[0m"
          rescue StandardError => e
            raise Error, "Failed to update repository: #{e.message}"
          end
        end

        def self.clone(repository)
          success = system("git clone #{repository.url} #{repository.path}", out: File::NULL)

          raise Error, 'Failed to clone repository' unless success
        end

        def self.remove(repository)
          FileUtils.rm_rf(repository.path)

          raise Error, 'Failed to remove repository' if repository.exists_locally?
        end
      end
    end
  end
end
