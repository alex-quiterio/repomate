# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Removes a repository from the sync list
      class Add < Base
        def execute
          return puts "\e[31mRepository URL is required. Use -l or --repo-url.\e[0m" unless config.repo_url

          repository = Domain::Repository.from_url(config.repo_url, config.code_path)
          result = store.add(repository)

          puts result.message
        rescue Infra::Git::Operations::Error => e
          puts "\e[31mError synchronizing the repository locally: #{e.message}\e[0m"
        end
      end
    end
  end
end
