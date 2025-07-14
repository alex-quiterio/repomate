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
          repositories = store.all
          
          if config.pattern
            repositories = repositories.select { |repo| repo.url.include?(config.pattern) }
            if repositories.empty?
              puts "No repositories match pattern '#{config.pattern}'"
              return
            end
            puts "Syncing #{repositories.length} repositories matching pattern '#{config.pattern}'..."
          end
          
          repositories.each do |repository|
            sync_repository(repository)
          rescue Infra::Git::Operations::Error => e
            puts "Error syncing #{repository.url}: #{e.message}"
          end
        end
      end
    end
  end
end
