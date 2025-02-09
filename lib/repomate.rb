# frozen_string_literal: true

require 'fileutils'

# Repomate module serves as the namespace for the entire application.
# It encapsulates all the classes and modules related to the Repomate application.
module Repomate
  class Error < StandardError; end

  require_relative 'repomate/version'
  require_relative 'repomate/domain/result'
  require_relative 'repomate/domain/repository'
  require_relative 'repomate/config/configuration'
  require_relative 'repomate/infra/git/operations'
  require_relative 'repomate/infra/persistence/repository_store'
  require_relative 'repomate/application/commands/base'
  require_relative 'repomate/application/commands/add'
  require_relative 'repomate/application/commands/list'
  require_relative 'repomate/application/commands/remove'
  require_relative 'repomate/application/commands/sync'
  require_relative 'repomate/application/command_factory'
  require_relative 'repomate/application/manager'
  require_relative 'repomate/interface/cli'
end
