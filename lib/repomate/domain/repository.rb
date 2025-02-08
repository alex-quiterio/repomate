# frozen_string_literal: true

module Repomate
  module Domain
    # Represents a Git repository
    class Repository
      attr_reader :url, :name, :path

      def initialize(url:, code_path:)
        @url = url.strip
        @name = extract_name_from_url(url)
        @path = File.join(code_path, @name)
      end

      def exists_locally?
        Dir.exist?(@path)
      end

      def ==(other)
        other.is_a?(Repository) && other.url == url
      end

      def valid?
        !url.empty? && url.include?('/')
      end

      private

      def extract_name_from_url(url)
        url.split('/').last.gsub('.git', '')
      end
    end
  end
end
