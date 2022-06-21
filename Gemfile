# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in bali.gemspec.
gemspec

gem 'bulma-rails', '~> 0.9.3'
gem 'sassc-rails'
gem 'sprockets-rails'

gem 'lookbook'
gem 'ransack'
gem 'view_component'
gem 'view_component-contrib'

# Start debugger with binding.b [https://github.com/ruby/debug]
gem 'debug', '>= 1.0.0'

group :development do
  gem 'jsbundling-rails'
  gem 'puma', '~> 5.2'
  gem 'rubocop', '~> 1', require: false
  gem 'rubocop-rails', '~> 2'
end

group :test do
  gem 'capybara', '~> 3'
  gem 'rspec-rails', '~> 5'
  gem 'simplecov', require: false
  gem 'sqlite3'
end
