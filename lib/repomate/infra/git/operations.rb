# frozen_string_literal: true

module Repomate
  module Infra
    module Git
      # Contains operations for working with Git repositories
      class Operations
        class Error < StandardError; end

        def self.update(repository)
          Dir.chdir(repository.path) do
            # Try main branch first, then master if main doesn't exist
            success = system('git stash', out: File::NULL)
            if system('git checkout main', out: File::NULL)
              success &&= system('git pull', out: File::NULL)
            else
              success &&= system('git checkout master', out: File::NULL)
              success &&= system('git pull', out: File::NULL)
            end

            raise Error, 'Failed to update repository' unless success
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
