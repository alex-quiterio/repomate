# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Sync command for syncing repositories
      class Sync < Base
        def execute
          repos_to_sync = optionally_filter_repositories_by_pattern(store.all)
          return puts 'No repositories to sync' if repos_to_sync.empty?

          puts "\e[34mSyncing #{repos_to_sync.length} repositories...\e[0m"

          repos_to_sync.each do |repository|
            sync_repository(repository)
          rescue Infra::Git::Operations::Error => e
            puts "Error syncing #{repository.url}: #{e.message}"
          end

          puts "\e[34mSync complete ✨\e[0m"
        end

        private

        def optionally_filter_repositories_by_pattern(repositories)
          return repositories unless config.pattern

          repositories.select { |repo| repo.url.include?(config.pattern) }
        end

        def sync_repository(repository)
          if repository.exists_locally?
            puts "♲ #{repository.name}..."
            Infra::Git::Operations.update(repository)
          else
            Infra::Git::Operations.clone(repository)
          end
        end
      end
    end
  end
end
