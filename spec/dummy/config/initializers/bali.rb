# frozen_string_literal: true

Bali.config do |config|
  # Disable Rich Text Editor when DISABLE_RICH_TEXT_EDITOR environment variable is set
  # This prevents the component from rendering and avoids loading TipTap dependencies
  config.rich_text_editor_enabled = !ENV['DISABLE_RICH_TEXT_EDITOR']
end
