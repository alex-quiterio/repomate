# frozen_string_literal: true

module Repomate
  module Infra
    module Persistence
      # Stores repositories in a file
      class RepositoryStore
        def initialize(config_file_path)
          @config_file_path = config_file_path
          ensure_config_file_exists
        end

        def all
          return [] unless File.exist?(@config_file_path)

          File.readlines(@config_file_path)
              .map(&:strip)
              .reject(&:empty?)
              .map { |url| Domain::Repository.new(url: url, code_path: File.dirname(@config_file_path)) }
        end

        def add(repository)
          return Domain::Result.failure('Invalid repository URL') unless repository.valid?
          return Domain::Result.failure('Repository already exists') if contains?(repository)

          File.open(@config_file_path, 'a') { |f| f.puts repository.url }
          Infra::Git::Operations.clone(repository)

          Domain::Result.success("Added #{repository.url} to sync list")
        end

        def remove(repository)
          return Domain::Result.failure('Repository not found') unless contains?(repository)

          repos = all.reject { |r| r == repository }
          File.write(@config_file_path, "#{repos.map(&:url).join("\n")}\n")
          Infra::Git::Operations.remove(repository)

          Domain::Result.success("Removed #{repository.url} from sync list")
        end

        def contains?(repository)
          all.any? { |r| r == repository }
        end

        private

        def ensure_config_file_exists
          FileUtils.touch(@config_file_path) unless File.exist?(@config_file_path)
        end
      end
    end
  end
end
