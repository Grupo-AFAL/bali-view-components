# frozen_string_literal: true

# Non-UI concerns and utilities that are NOT required by default.
# Consuming apps that use these should add to their Gemfile or an initializer:
#
#   require "bali/extras"
#
# Or require individual concerns:
#
#   require "bali/concerns/soft_delete"
#   require "bali/concerns/global_id_accessors"

# Configuration for DeviceVariants concern
Bali.mattr_accessor :ios_native_app_user_agent, default: /Turbo Native \(iOS\)/
Bali.mattr_accessor :android_native_app_user_agent, default: /Turbo Native \(Android\)/
Bali.mattr_accessor :sketchy_request_usernames, default: %w[admin cnadmin]

require "bali/concerns/controllers/device_variants"
require "bali/concerns/global_id_accessors"
require "bali/concerns/mailers/recipients_sanitizer"
require "bali/concerns/mailers/utm_params"
require "bali/concerns/numeric_attributes_with_commas"
require "bali/concerns/soft_delete"
