# frozen_string_literal: true

require 'fileutils'
require 'optparse'

module Repomate
  module Config
    # Configuration options
    class Configuration
      attr_reader :code_path, :config_file_path, :command, :repo_url

      def initialize
        home_path = ENV['HOME']
        # Set defaults
        @code_path = "#{home_path}/code"
        @config_file_path = "#{home_path}/.config/repomate/repos.txt"
        @command = 'sync'
        @repo_url = nil

        parse_options
        ensure_directories
      end

      private

      def parse_options
        OptionParser.new do |opts|
          opts.banner = 'Usage: repomate [options] [command]'
          opts.separator("\nCommands:")
          opts.separator('  sync                     Sync all repositories (default)')
          opts.separator('  add REPO_URL            Add repository to sync list')
          opts.separator('  remove REPO_URL         Remove repository from sync list')
          opts.separator('  list                    Show all repositories in sync list')
          opts.separator("\nOptions:")

          opts.on('--code-path PATH', 'Set code directory path') do |path|
            @code_path = path
          end

          opts.on('-c', '--config-file PATH', 'Set config file path') do |path|
            @config_file_path = path
          end

          opts.on('-h', '--help', 'Display this help message') do
            puts opts
            exit
          end

          opts.on('-v', '--version', 'Display version') do
            puts "repomate #{Repomate::VERSION}"
            exit
          end
        end.parse!

        # Parse command and repository URL if provided
        return unless ARGV.any?

        @command = ARGV[0]
        @repo_url = ARGV[1] if ARGV[1]
      end

      def ensure_directories
        FileUtils.mkdir_p(@code_path)
        config_dir = File.dirname(@config_file_path)
        FileUtils.mkdir_p(config_dir)

        unless File.exist?(@config_file_path)
          puts "Creating config file at #{@config_file_path}"
          FileUtils.touch(@config_file_path)
        end
      rescue StandardError => e
        puts "Error creating directories: #{e.message}"
        exit 1
      end
    end
  end
end
