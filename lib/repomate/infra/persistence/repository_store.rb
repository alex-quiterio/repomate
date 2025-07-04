# frozen_string_literal: true

module Repomate
  module Infra
    module Persistence
      # Stores repositories in a file
      class RepositoryStore
        def initialize(config_file_path:, code_path:)
          raise 'Missing config_path or code_path' if config_file_path.nil?

          @config_file_path = config_file_path
          @code_path = code_path || config_file_path

          ensure_config_file_exists
          ensure_code_path_exists
        end

        def all
          return [] unless File.exist?(@config_file_path)

          File.readlines(@config_file_path)
              .map(&:strip)
              .reject(&:empty?)
              .map { |url| Domain::Repository.from_url(url, @code_path) }
        end

        def add(repository)
          return Domain::Result.failure('Invalid repository URL') unless repository.valid?
          return Domain::Result.failure('Repository already exists') if contains?(repository)

          Infra::Git::Operations.clone(repository)
          File.open(@config_file_path, 'a') { |f| f.puts repository.url }

          Domain::Result.success("#{repository.name} added 📦")
        end

        def remove(repository)
          return Domain::Result.failure('Repository not found') unless contains?(repository)

          repos = all.reject { |r| r == repository }
          File.write(@config_file_path, "#{repos.map(&:url).join("\n")}\n")
          Infra::Git::Operations.remove(repository)

          Domain::Result.success("#{repository.name} removed 🗑")
        end

        def contains?(repository)
          all.any? { |r| r == repository }
        end

        private

        def ensure_config_file_exists
          FileUtils.touch(@config_file_path) unless File.exist?(@config_file_path)
        end

        def ensure_code_path_exists
          FileUtils.mkdir_p(@code_path) unless Dir.exist?(@code_path)
        rescue Errno::EACCES => e
          raise "Could not create config directory #{@code_path} due to #{e.message}"
        rescue Errno::EEXIST => e
        end
      end
    end
  end
end
