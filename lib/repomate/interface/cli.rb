# frozen_string_literal: true

module Repomate
  module Interface
    # Command Line Interface
    class CommandsCLI
      def self.readline
        config = Repomate::Config::Configuration.new
        manager = Repomate::Application::Manager.new(config)

        # Also handle SIGINT (Ctrl+C) for better user experience
        trap('INT') do
          puts "\n\e[31mRepomate stopped ⏸️\e[0m"
          exit 1
        end

        manager.run
      end
    end
  end
end
