# frozen_string_literal: true

# Gemfile
source 'https://rubygems.org'

# Specify your gem's dependencies in repomate.gemspec
gemspec

group :development do
  gem 'pry', '~> 0.14.0'  # For debugging
  gem 'rake', '~> 13.0'
  gem 'rspec', '~> 3.0'
  gem 'rubocop', '~> 1.21'
  gem 'yard', '~> 0.9.0'  # For documentation
end

group :test do
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', '~> 0.21.0' # For test coverage
end
