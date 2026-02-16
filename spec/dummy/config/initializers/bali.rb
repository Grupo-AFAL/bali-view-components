# frozen_string_literal: true

Bali.config do |config|
  # Rich Text Editor is disabled by default to avoid loading TipTap dependencies
  # Set ENABLE_RICH_TEXT_EDITOR=1 to enable for testing
  config.rich_text_editor_enabled = ENV['ENABLE_RICH_TEXT_EDITOR'].present?

  # Block Editor is enabled in the dummy app for demonstration
  # In production apps, set to true only if @blocknote/core is installed
  config.block_editor_enabled = true
end
