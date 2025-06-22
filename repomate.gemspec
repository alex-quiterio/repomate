# frozen_string_literal: true

# repomate.gemspec
require_relative 'lib/repomate/version'

Gem::Specification.new do |spec|
  spec.name = 'repomate'
  spec.version = Repomate::VERSION
  spec.authors = ['Alex Quiterio']
  spec.email = ['your.email@example.com']

  spec.summary = 'A tool to manage and synchronize multiple git repositories'
  spec.description = 'Repomate helps you maintain a list of git repositories and keep them up to date with their remote sources'
  spec.homepage = 'https://github.com/yourusername/repomate'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md"
  }

  spec.files = Dir.glob('{bin,lib,shell}/**/*') + %w[LICENSE README.md]
  spec.bindir = 'bin'
  spec.executables = ['repomate']
  spec.require_paths = ['lib']

  spec.add_dependency 'fileutils'
  spec.add_dependency 'optparse'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
