# frozen_string_literal: true

module Repomate
  module Application
    # Error for unknown commands
    class UnknownCommandError < StandardError; end

    # Factory for creating command objects
    class CommandFactory
      COMMANDS = {
        sync: Commands::Sync,
        add: Commands::Add,
        remove: Commands::Remove,
        list: Commands::List
      }.freeze

      def self.create(name:, config:, store:)
        command_class = COMMANDS[name.to_sym]
        raise UnknownCommandError, "Unknown command: #{name}" unless command_class

        command_class.new(config: config, store: store)
      end
    end
  end
end
