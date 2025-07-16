# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Sync command for syncing repositories
      class Sync < Base
        def execute
          repositories = store.all
          if repositories.empty?
            puts "No repositories configured. Add some with 'add' command."
            return
          end

          if config.pattern
            repositories = repositories.select { |repo| repo.url.include?(config.pattern) }
            if repositories.empty?
              puts "No repositories match pattern '#{config.pattern}'"
              return
            end
            puts "\e[34mSyncing #{repositories.length} repositories matching pattern '#{config.pattern}'...\e[0m"
          else
            puts "\e[34mSyncing #{repositories.length} repositories..."
          end

          repositories.each do |repository|
            sync_repository(repository)
          rescue Infra::Git::Operations::Error => e
            puts "Error syncing #{repository.url}: #{e.message}"
          end

          puts "\e[34mSync complete ✨\e[0m"
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

        end
      end
    end
  end
end
