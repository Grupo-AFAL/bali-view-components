# frozen_string_literal: true

#
# Lookbook-optimized environment for fast component browsing.
#
# Based on development.rb but disables code reloading for faster page loads.
# Use this when browsing/reviewing components, not when actively editing.
#
# Usage: RAILS_ENV=lookbook bin/rails server -p 3001
#
# Trade-off:
# - Page loads: 200-500ms (vs 2-60 seconds in development)
# - Code changes: Require server restart (vs instant in development)
#

require_relative "development"

Rails.application.configure do
  # Required for non-development environments
  config.secret_key_base = "lookbook_dev_secret_key_base_not_for_production"
  # Disable code reloading - the main performance win
  # Rails won't check if 65+ component files changed on every request
  config.enable_reloading = false

  # Eager load all classes at startup
  # One-time cost at boot, but no per-request overhead
  config.eager_load = true

  # Cache classes in memory
  config.cache_classes = true

  # Enable action caching for even faster repeated loads
  config.action_controller.perform_caching = true
  config.cache_store = :memory_store

  # Disable verbose logging to reduce I/O
  config.active_record.verbose_query_logs = false
  config.active_record.query_log_tags_enabled = false
  config.log_level = :info
end
