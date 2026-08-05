# frozen_string_literal: true

module Bali
  module DeleteLink
    class Preview < ApplicationViewComponentPreview
      # Takes the same three axes as Button and Link. `variant: :ghost` (the default) and
      # `variant: :link` carry no colour of their own, so those two keep the destructive
      # red; naming any other colour hands the button over to it.
      # @param name text
      # @param variant select { choices: [ghost, link, neutral, primary, secondary, accent, info, success, warning, error] }
      # @param style select { choices: [~, outline, soft] }
      # @param size select { choices: [~, xs, sm, md, lg, xl] }
      # @param icon toggle
      # @param skip_confirm toggle
      # rubocop:disable Metrics/ParameterLists
      def default(name: nil, variant: :ghost, style: nil, size: nil, icon: false,
                  skip_confirm: false)
        # rubocop:enable Metrics/ParameterLists
        render DeleteLink::Component.new(
          name: name,
          href: '/lookbook',
          variant: variant.to_sym,
          style: style&.to_sym,
          size: size&.to_sym,
          icon: icon,
          skip_confirm: skip_confirm
        )
      end

      # `icon:` takes an icon name as well as `true`, which is what `icon:` used to be
      # for. One keyword now says both whether and which.
      # @param icon text
      def with_named_icon(icon: 'circle-x')
        render DeleteLink::Component.new(name: 'Discard', href: '/lookbook', icon: icon)
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
      #
      # The disabled state is a `<button aria-disabled="true">`, not the `<a disabled>` it
      # used to be — HTML has no disabled attribute on an anchor, so that state existed only
      # as paint. It stays focusable on purpose: `disabled` would drop it out of the tab
      # order, taking the hover card with it, and the reason would be mouse-only.
      # @param disabled toggle
      def with_hovercard(disabled: true)
        render DeleteLink::Component.new(
          href: '/lookbook',
          disabled: disabled,
          disabled_hover_url: '/show-content-in-hovercard'
        )
      end

      # Custom classes can be applied to both the button and the wrapping form.
      # @param size select { choices: [~, xs, sm, md, lg, xl] }
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
