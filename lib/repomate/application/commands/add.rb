# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Removes a repository from the sync list
      class Add < Base
        def execute
          return puts 'Error: Repository namespace is required' unless config.namespace

          repository = Domain::Repository.new(namespace: config.namespace, code_path: config.code_path)
          result = store.add(repository)

          puts result.message
        rescue Infra::Git::Operations::Error => e
          puts "Error synchronizing the repository locally: #{e.message}"
        end
      end
    end
  end
end
