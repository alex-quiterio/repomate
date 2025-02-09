# frozen_string_literal: true

module Repomate
  module Domain
    # Represents a Git repository
    class Repository
      DEFAULT_PROTOCOL = 'git'
      DEFAULT_PROVIDER = 'github.com'

      attr_reader :path, :namespace

      def self.from_url(url, code_path)
        namespace = url.split(':').last.gsub('.git', '')
        new(code_path: code_path, namespace: namespace)
      end

      def initialize(code_path:, namespace:)
        @protocol = DEFAULT_PROTOCOL
        @provider = DEFAULT_PROVIDER
        @namespace = namespace
        @path = File.join(code_path, name)
      end

      def exists_locally?
        Dir.exist?(@path)
      end

      def name
        namespace.split('/').last
      end

      def url
        "#{@protocol}@#{@provider}:#{@namespace}.git"
      end

      def ==(other)
        other.is_a?(Repository) && other.url == url
      end

      def valid?
        !url.empty? && url.include?('/')
      end
    end
  end
end
