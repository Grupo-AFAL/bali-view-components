# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in bali.gemspec.
gemspec

gem 'bulma-rails', '~> 0.9.3'
gem 'dartsass-rails'
gem 'device_detector'
gem 'sprockets-rails'

gem 'lookbook'
gem 'ransack'
gem 'simple_command'
gem 'view_component'
gem 'view_component-contrib'

# Start debugger with binding.b [https://github.com/ruby/debug]
gem 'debug', '>= 1.0.0'

group :development do
  gem 'jsbundling-rails'
  gem 'puma', '< 7'
  gem 'rubocop', '~> 1', require: false
  gem 'rubocop-rails', '~> 2'
end

group :test do
  gem 'capybara', '~> 3'
  gem 'simplecov', require: false
  gem 'sqlite3'
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'rspec-rails', '~> 5'
end
