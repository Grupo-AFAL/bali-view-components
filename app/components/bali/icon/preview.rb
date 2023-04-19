# frozen_string_literal: true

module Bali
  module Icon
    class Preview < ApplicationViewComponentPreview
      # Icon
      # ----
      # Use the default icon component whenever you need to display an icon.
      def default
        render Icon::Component.new('poo')
      end

      # Icon with a custom class
      # ------------------------
      # Add a custom class to the icon component whenever you need to customize it.
      def with_custom_class
        render Icon::Component.new('snowflake', class: 'has-text-info')
      end

      # All existing icons
      # ------------------
      # This is a preview of all icons that are available in Bali.
      def all_existing_icons
        render_with_template(
          template: 'bali/icon/previews/default', 
          locals: { icons: Bali::Icon::Options.icons.keys }
        )
      end
    end
  end
end
