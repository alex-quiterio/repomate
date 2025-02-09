# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Removes a repository from the sync list
      class Add < Base
        def execute
          return puts 'Error: Repository name is required' unless config.repo_name

          repository = Domain::Repository.new(name: config.repo_name, code_path: config.code_path)
          result = store.add(repository)

          puts result.message
        rescue Infra::Git::Operations::Error => e
          puts "Error synchronizing the repository locally: #{e.message}"
        end
      end
    end
  end
end
