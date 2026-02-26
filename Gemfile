# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in bali.gemspec.
gemspec

gem "caxlsx", "~> 4.1"
gem "csv"
gem "device_detector"
gem "propshaft"
gem "rrule", git: "https://github.com/square/ruby-rrule"
gem "tailwindcss-rails", "~> 4.0"

gem "lookbook"
gem "pagy", ">= 43.0"
gem "ransack"
gem "simple_command"
gem "view_component"
gem "view_component-contrib"

# Icons
gem "lucide-rails"

# Start debugger with binding.b [https://github.com/ruby/debug]
gem "debug", ">= 1.0.0"

group :development do
  gem "puma", "< 7"
  gem "rubocop-rails-omakase", require: false
  gem "yard", "~> 0.9"
end

group :test do
  gem "capybara", "~> 3"
  gem "simplecov", require: false
  gem "sqlite3", "~> 2.0"
end

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "dotenv"
  gem "turbo-rails", "~> 2"
  gem "jsbundling-rails"
end
