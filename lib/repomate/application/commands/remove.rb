# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Removes a repository from the sync list
      class Remove < Base
        def execute
          return puts 'Error: Repository namespace is required' unless config.namespace

          repository = Domain::Repository.new(namespace: config.namespace, code_path: config.code_path)
          result = store.remove(repository)
          Infra::Git::Operations.remove(repository)

          puts result.message
        rescue Infra::Git::Operations::Error => e
          puts "Error removing the repository locally: #{e.message}"
        end
      end
    end
  end
end
