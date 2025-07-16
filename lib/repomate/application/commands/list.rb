# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Lists repositories in the sync list
      class List < Base
        def execute
          repos = store.all
          return puts "No repositories configured. Add some with 'add' command." if repos.empty?

          repos = repos.select { |repo| repo.url.include?(config.pattern) } if config.pattern

          puts "\e[34mPath to code directory:\e[0m"
          puts "- #{config.code_path}"

          puts "\e[34mMatched repositories in the config file [#{repos.length}]:\e[0m"
          repos.each { |repo| puts "- #{repo.url}" }
          puts '- ...' if repos.empty?
        end
      end
    end
  end
end
