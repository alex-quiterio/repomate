# frozen_string_literal: true

require 'optparse'

module Repomate
  module Config
    # Configuration options
    class Configuration
      attr_reader :code_path, :config_file_path, :command, :repo_url, :pattern

      def initialize
        home_path = ENV['HOME']
        # Set defaults
        @code_path = "#{home_path}/code"
        @config_file_path = "#{home_path}/code/.subscribed-repos"
        @command = ARGV[0] || 'sync'

        parse_options!
        ensure_directories!
      end

      private

      def parse_options!
        OptionParser.new do |opts|
          add_docs(opts)
          add_config_options(opts)
        end.parse!
      end

      def ensure_directories!
        FileUtils.mkdir_p(@code_path)
        config_dir = File.dirname(@config_file_path)
        FileUtils.mkdir_p(config_dir)

        unless File.exist?(@config_file_path)
          puts "Repomate: Creating config file at #{@config_file_path}"
          FileUtils.touch(@config_file_path)
        end
      rescue StandardError => e
        puts "Repomate: Error creating directories: #{e.message}"
        exit 1
      end

      def add_docs(opts)
        opts.banner = 'Usage: repomate [command] [options]'
        opts.separator("\nAvailable Commands:")
        opts.separator("→  #{Repomate::Application::CommandFactory::COMMANDS.keys.sort.join(', ')}")
        opts.separator("\nOptions:")
      end

      def add_config_options(opts)
        opts.on('-l', '--repo-url NAME',
                'Set repository URL (e.g. git@github.com:alex-quiterio/repomate.git)') do |name|
          @repo_url = name
        end
        opts.on('-p', '--pattern PATTERN',
                'Filter repositories by pattern (for sync command only)') do |pattern|
          @pattern = pattern
        end

        opts.on('-h', '--help', 'Help 🙈') do
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Version') do
          puts "repomate #{Repomate::VERSION} 🎸"
          exit
        end
      end
    end
  end
end
