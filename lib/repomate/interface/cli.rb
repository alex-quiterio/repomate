# frozen_string_literal: true

module Repomate
  module Interface
    # Command Line Interface
    class CLI
      def self.start
        config = Repomate::Config::Configuration.new
        manager = Repomate::Application::Manager.new(config)
        manager.run
      end
    end
  end
end
