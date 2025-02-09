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

          return sync_single_repo if config.repo_url

          store.all.each do |repository|
            sync_repository(repository)
          rescue Infra::Git::Operations::Error => e
            puts "Error syncing #{repository.url}: #{e.message}"
          end
        end

        private

        def sync_repository(repository)
          if repository.exists_locally?
            Infra::Git::Operations.update(repository)
          else
            Infra::Git::Operations.clone(repository)
          end
        end

        def sync_single_repo
          repository = Domain::Repository.new(url: config.repo_url, code_path: config.code_path)
          sync_repository(repository)
        end
      end
    end
  end
end
