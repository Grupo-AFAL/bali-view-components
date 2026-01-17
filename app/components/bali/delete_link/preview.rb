# frozen_string_literal: true

module Bali
  module DeleteLink
    class Preview < ApplicationViewComponentPreview
      # @param name text
      # @param size select { choices: [~, xs, sm, md, lg] }
      # @param icon toggle
      # @param skip_confirm toggle
      def default(name: nil, size: nil, icon: false, skip_confirm: false)
        render DeleteLink::Component.new(
          name: name,
          href: '/lookbook',
          size: size&.to_sym,
          icon: icon,
          skip_confirm: skip_confirm
        )
      end

      # @param custom_confirm text "Custom confirmation message"
      def with_custom_confirm(custom_confirm: 'Are you absolutely sure you want to delete this?')
        render DeleteLink::Component.new(
          href: '/lookbook',
          confirm: custom_confirm
        )
      end

      # Disabled delete links can show a hover card explaining why deletion is not available.
      # The `disabled_hover_url` should return content explaining why deletion is disabled.
      # @param disabled toggle
      def with_hovercard(disabled: true)
        render DeleteLink::Component.new(
          href: '/lookbook',
          disabled: disabled,
          disabled_hover_url: '/show-content-in-hovercard'
        )
      end

      # Custom classes can be applied to both the button and the wrapping form.
      # @param size select { choices: [~, xs, sm, md, lg] }
      # @param form_class select { choices: [~, bg-base-200, bg-success/20, bg-warning/20] }
      def with_custom_classes(size: nil, form_class: nil)
        render DeleteLink::Component.new(
          href: '/lookbook',
          size: size&.to_sym,
          form_class: form_class
        )
      end

      # When `authorized: false`, the component does not render at all.
      # This is useful for conditionally hiding delete links based on permissions.
      # @param authorized toggle
      def with_authorization(authorized: false)
        render DeleteLink::Component.new(
          href: '/lookbook',
          authorized: authorized
        )
      end
    end
  end
end
