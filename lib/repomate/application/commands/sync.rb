# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Sync command for syncing repositories
      class Sync < Base
        def execute
          if store.all.empty?
            puts "No repositories configured. Add some with 'add' command."
            return
          end

          if config.repo_url
            sync_repository(
              Domain::Repository.from_url(config.repo_url, config.code_path)
            )
          else
            sync_all_repos
          end

          puts 'Sync complete ✨'
        end

        private

        def sync_repository(repository)
          if repository.exists_locally?
            puts "Syncing #{repository.name}..."
            Infra::Git::Operations.update(repository)
          else
            Infra::Git::Operations.clone(repository)
          end
        end

        def sync_all_repos
          store.all.each do |repository|
            sync_repository(repository)
          rescue Infra::Git::Operations::Error => e
            puts "Error syncing #{repository.url}: #{e.message}"
          end
        end
      end
    end
  end
end
