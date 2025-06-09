# frozen_string_literal: true

module Repomate
  module Domain
    # Represents a Git repository
    class Repository
      DEFAULT_PROTOCOL = 'git'
      DEFAULT_PROVIDER = 'github.com'

      attr_reader :path, :name

      def self.from_url(url, code_path)
        protocol, provider = url.split(':').first.split('@')
        name = url.split(':').last.gsub('.git', '')

        new(code_path: code_path, name: name, protocol: protocol, provider: provider)
      end

      def initialize(name:, code_path:, protocol: nil, provider: nil)
        @protocol = protocol || DEFAULT_PROTOCOL
        @provider = provider || DEFAULT_PROVIDER
        @name = name
        @path = File.join(code_path, name)
      end

      def exists_locally?
        Dir.exist?(@path)
      end

      def url
        "#{@protocol}@#{@provider}:#{@name}.git"
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
