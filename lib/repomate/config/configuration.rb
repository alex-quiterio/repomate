# frozen_string_literal: true

require 'optparse'
require 'json'

module Repomate
  module Config
    # Configuration options
    class Configuration
      attr_reader :code_path, :config_file_path, :command, :repo_url

      def initialize
        home_path = ENV['HOME']
        # Set defaults
        @code_path = "#{home_path}/code"
        @config_file_path = "#{home_path}/code/.subscribed-repos"
        @command = ARGV[0] || 'sync'

        # Check for .repomaterc in current directory first
        load_repomaterc_if_exists!
        
        parse_options!
        ensure_directories!
      end

      private

      def load_repomaterc_if_exists!
        repomaterc_path = File.join(Dir.pwd, '.repomaterc')
        return unless File.exist?(repomaterc_path)

        begin
          config_data = JSON.parse(File.read(repomaterc_path))
          
          # Update code_path from repos_root_path if present
          @code_path = config_data['repos_root_path'] if config_data['repos_root_path']
          
          # Create a temporary config file with repositories if it has them
          if config_data['repositories'] && !config_data['repositories'].empty?
            temp_config_dir = File.join(@code_path, '.repomate')
            FileUtils.mkdir_p(temp_config_dir)
            @config_file_path = File.join(temp_config_dir, '.subscribed-repos')
            
            # Write repositories to the config file
            File.write(@config_file_path, config_data['repositories'].join("\n") + "\n")
          end
          
          puts "📋 Loaded configuration from .repomaterc"
        rescue JSON::ParserError => e
          puts "Warning: Invalid JSON in .repomaterc: #{e.message}"
          puts "Falling back to default configuration"
        rescue StandardError => e
          puts "Warning: Error reading .repomaterc: #{e.message}"
          puts "Falling back to default configuration"
        end
      end

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
          puts "Creating config file at #{@config_file_path}"
          FileUtils.touch(@config_file_path)
        end
      rescue StandardError => e
        puts "Error creating directories: #{e.message}"
        exit 1
      end

      def add_docs(opts)
        opts.banner = 'Usage: repomate [command] [options]'
        opts.separator("\nAvailable Commands:")
        opts.separator("→  #{Repomate::Application::CommandFactory::COMMANDS.keys.sort.join(', ')}")
        opts.separator("\nOptions:")
      end

      def add_config_options(opts)
        opts.on('-p', '--code-path PATH', 'Set code directory path') { |path| @code_path = path }
        opts.on('-c', '--config-file PATH', 'Set config file path') do |path|
          @config_file_path = path
        end
        opts.on('-l', '--repo-url NAME',
                'Set repository URL (e.g. git@github.com:alex-quiterio/repomate.git)') do |name|
          @repo_url = name
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
