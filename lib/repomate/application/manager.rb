# frozen_string_literal: true

module Repomate
  module Application
    # Manages the execution of commands
    class Manager
      def initialize(config)
        @config = config
        @store = Persistence::RepositoryStore.new(config.config_file_path)
      end

      def run
        command = Commands::Factory.create(
          command_name: @config.command,
          config: @config,
          store: @store
        )
        command.execute
      rescue Commands::UnknownCommandError => e
        puts e.message
        exit 1
      end
    end
  end
end
