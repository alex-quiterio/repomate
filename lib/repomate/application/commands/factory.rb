# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Error for unknown commands
      class UnknownCommandError < StandardError; end

      # Factory for creating command objects
      class Factory
        COMMANDS = {
          sync: Commands::Sync,
          add: Commands::Add,
          remove: Commands::Remove,
          list: Commands::List
        }.freeze

        def self.create(command_name:, config:, store:)
          command_class = COMMANDS[command_name.to_sym]
          raise UnknownCommandError, "Unknown command: #{command_name}" unless command_class

          command_class.new(config: config, store: store)
        end
      end
    end
  end
end
