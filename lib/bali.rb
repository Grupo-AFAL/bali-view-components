# frozen_string_literal: true

require 'bali/filter_form'
require 'bali/form_builder/html_utils'
require 'bali/form_builder/shared_utils'
require 'bali/form_builder/shared_date_utils'
require 'bali/layout_concern'
require 'bali/types/time_value'
require 'bali/types/month_value'
require 'bali/types/date_range_value'
require 'bali/utils'
require 'bali/html_element_helper'
require 'bali/path_helper'
require 'bali/form_helper'
require 'bali/auto_submit_select_helper'
require 'bali/icon_tag_helper'
require 'bali/time_periods/select_options'

Dir[File.join(File.dirname(__FILE__), 'bali/concerns', '**/*.rb')].each do |concern|
  require concern
end

builder_helpers = File.join(File.dirname(__FILE__), 'bali/form_builder', '*_fields.rb')

Dir.glob(builder_helpers).each do |builder_helper|
  require builder_helper
end

Dir[File.join(File.dirname(__FILE__), 'bali/commands', '**/*.rb')].each do |command|
  require command
end

require 'bali/form_builder'

require 'bali/version'
require 'bali/engine'

module Bali
  mattr_accessor :native_app, default: false
  mattr_accessor :custom_icons, default: {}
  mattr_accessor :ios_native_app_user_agent, default: /Turbo Native \(iOS\)/
  mattr_accessor :android_native_app_user_agent, default: /Turbo Native \(Android\)/
  mattr_accessor :sketcky_request_usernames, default: %w[admin cnadmin]

  # Rich Text Editor configuration
  # Set to true to enable the Rich Text Editor component (requires TipTap dependencies)
  mattr_accessor :rich_text_editor_enabled, default: false

  # Block Editor configuration
  # Set to true to enable the Block Editor component (requires @blocknote/core)
  mattr_accessor :block_editor_enabled, default: false

  # Block Editor upload configuration
  # Authorization lambda: receives the controller instance, must return truthy to allow upload.
  # Example: ->(controller) { controller.current_user.present? }
  mattr_accessor :block_editor_upload_authorize, default: nil

  # Custom upload handler lambda: receives (uploaded_file, controller), must return a URL string.
  # When nil, defaults to Active Storage (creates unattached blob).
  # Note: Default Active Storage handler creates unattached blobs. Configure a purge job
  # (e.g., ActiveStorage::Blob.unattached.where(created_at: ..2.days.ago).find_each(&:purge_later))
  # or use a custom handler for production workloads.
  # Example: ->(file, controller) { MyUploader.upload(file) }
  mattr_accessor :block_editor_upload_handler, default: nil

  # Allowed upload content types (array of MIME type strings).
  # Default: %w[image/jpeg image/png image/gif image/webp]
  mattr_accessor :block_editor_allowed_upload_types, default: nil

  # Maximum upload file size in bytes. Default: 10.megabytes
  mattr_accessor :block_editor_max_upload_size, default: nil

  # Explicit upload URL path. When set, the component uses this instead of
  # auto-resolving from engine routes. Useful if you don't mount the engine.
  # Example: '/api/block_editor/uploads'
  mattr_accessor :block_editor_upload_url, default: nil

  def self.add_icon(name, svg_str)
    custom_icons[name.to_s] = svg_str
  end

  def self.config
    yield(self)
  end
end
