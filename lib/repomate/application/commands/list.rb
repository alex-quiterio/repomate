# frozen_string_literal: true

module Repomate
  module Application
    module Commands
      # Lists repositories in the sync list
      class List < BaseCommand
        def execute
          repos = store.all
          if repos.empty?
            puts "No repositories configured. Add some with 'add' command."
            return
          end

          puts 'Repositories in sync list:'
          repos.each { |repo| puts "- #{repo.url}" }
        end
      end
    end
  end
end
