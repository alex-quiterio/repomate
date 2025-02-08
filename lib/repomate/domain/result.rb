# frozen_string_literal: true

module Repomate
  module Domain
    # Represents the result of an operation
    class Result
      attr_reader :message

      def self.success(message)
        new(message, true)
      end

      def self.failure(message)
        new(message, false)
      end

      def success?
        @success
      end

      private

      def initialize(message, success)
        @message = message
        @success = success
      end
    end
  end
end
