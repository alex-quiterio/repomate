# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Base class for all commands
      class BaseCommand
        attr_reader :config, :store

        def initialize(config:, store:)
          @config = config
          @store = store
        end

        def execute
          raise NotImplementedError, "#{self.class} must implement #execute"
        end
      end
    end
  end
end
