# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in bali.gemspec.
gemspec

gem 'bulma-rails', '~> 1.0'
gem 'caxlsx', '~> 4.1'
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
  gem 'puma', '< 7'
  gem 'rubocop', '~> 1', require: false
  gem 'rubocop-rails', '~> 2'
end

group :test do
  gem 'capybara', '~> 3'
  gem 'simplecov', require: false
  gem 'sqlite3', '~> 1.4'
end

group :development, :test do
  gem 'dotenv'
  gem 'importmap-rails', '~> 2.0'
  gem 'rspec-rails', '~> 6'
  gem 'stimulus-rails', '~> 1.3'
  gem 'turbo-rails', '~> 2'
end
