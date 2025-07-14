# frozen_string_literal: true

require 'json'

module Repomate
  module Application
    module Commands
      # Initializes a new .repomaterc configuration file
      class Init < Base
        def execute
          config_path = File.join(Dir.pwd, '.repomaterc')
          
          if File.exist?(config_path)
            puts "Error: .repomaterc already exists in current directory"
            return
          end

          # Get existing repositories from the store
          repositories = store.all.map(&:url)
          
          # Create the configuration structure
          config_data = {
            repositories: repositories,
            repos_root_path: config.code_path
          }

          # Write the configuration file
          File.write(config_path, JSON.pretty_generate(config_data))
          
          puts "✅ Created .repomaterc with #{repositories.length} repositories"
          puts "📁 Root path set to: #{config.code_path}"
        rescue StandardError => e
          puts "Error creating .repomaterc: #{e.message}"
        end
      end
    end
  end
end
