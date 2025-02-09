# frozen_string_literal: true

module Repomate
  module Domain
    # Represents a Git repository
    class Repository
      DEFAULT_PROTOCOL = 'git'
      DEFAULT_PROVIDER = 'github.com'
      attr_reader :name, :path, :namespace, :protocol, :provider

      def initialize(code_path:, url: '', namespace: '')
        @protocol = DEFAULT_PROTOCOL
        @provider = DEFAULT_PROVIDER

        @namespace = namespace
        @namespace = extract_namespace_from(url) if namespace.empty?

        @name = extract_name_from_namespace(@namespace)
        @path = File.join(code_path, @name)
      end

      def exists_locally?
        Dir.exist?(@path)
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

      private

      def extract_namespace_from(link)
        link.split(':').last.gsub('.git', '')
      end

      def extract_name_from_namespace(namespace)
        namespace.split('/').last
      end
    end
  end
end
