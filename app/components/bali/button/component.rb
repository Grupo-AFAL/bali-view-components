# frozen_string_literal: true

module Bali
  module Button
    class Component < ApplicationViewComponent
      include Bali::DeprecatedIconName
      include Bali::LocalOverlay

      # One table for Button, Link and DeleteLink. See Bali::ButtonTaxonomy for
      # why `outline` is a `style:` here and no longer a `variant:`.
      VARIANTS = Bali::ButtonTaxonomy::VARIANTS
      STYLES = Bali::ButtonTaxonomy::STYLES
      SIZES = Bali::ButtonTaxonomy::SIZES

      # The slot and the `icon:` keyword are the same concept written two ways, and now
      # under the same word: the slot is the one that takes options (`with_icon('star',
      # class: 'text-error')`), so it wins when both are given.
      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }
      renders_one :icon_right, ->(name, **options) { Icon::Component.new(name, **options) }

      # @param variant [Symbol] Colour, from Bali::ButtonTaxonomy::VARIANTS
      # @param style [Symbol] Fill, from Bali::ButtonTaxonomy::STYLES
      # @param size [Symbol] Scale, from Bali::ButtonTaxonomy::SIZES
      # @param icon [String, Symbol] Icon name, drawn before the label.
      # @param type [String, Symbol] The HTML `type` attribute (`:button`, `:submit`,
      #   `:reset`) — never a look. Bali::Link used to take a `type:` that meant the colour,
      #   and it is gone in v3 exactly because of this collision.
      # @param icon_name [String, nil] @deprecated Removed in Bali 4.0. Use `icon:`.
      # @param modal [Hash] `{ id: "health-modal", local: true }` — the button opens a
      #   modal already rendered on the page, by name. Only the local mode: a button has
      #   no href to fetch, so the remote mode stays on Bali::Link. `id:` is mandatory.
      # @param drawer [Hash] Same contract as `modal:`, for a drawer.
      # rubocop:disable Metrics/ParameterLists
      def initialize(name: nil, variant: nil, style: nil, size: nil, icon: nil,
                     icon_name: nil, type: :button, disabled: false, loading: false,
                     responsive: true, modal: false, drawer: false, **options)
        @name = name
        @modal_options = validate_local_only_overlay!(:modal, modal)
        @drawer_options = validate_local_only_overlay!(:drawer, drawer)
        @variant_class = Bali::ButtonTaxonomy.variant!(self.class, variant)
        @style_class = Bali::ButtonTaxonomy.style!(self.class, style)
        @size_class = Bali::ButtonTaxonomy.size!(self.class, size)
        @icon = icon || deprecated_icon_name(icon_name)
        @type = type
        @disabled = disabled
        @loading = loading
        @responsive = responsive
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      private

      # No `loading` class here, and that is the whole point: in daisyUI 5 `.loading`
      # IS the spinner, not a modifier that adds one. It sets `aspect-ratio: 1`, a
      # width of six selector units and `background-color: currentColor` masked by
      # the spinner SVG — so on the `<button>` it collapsed the box from 66x40 to
      # 34x40 and painted it as the spinner, with the label still inside showing
      # through the holes in the mask (#839). The spinner the template renders
      # inside the button is the whole of the loading state.
      def button_classes
        class_names(
          "btn",
          @variant_class,
          @style_class,
          @size_class,
          "btn-disabled" => @disabled,
          "max-sm:btn-square" => responsive_icon_only?
        )
      end

      # `loading:` disables the button. It always did — `.loading` carried
      # `pointer-events: none` — but it did it as a side effect of a class that also
      # destroyed the button's box. Saying it in the attribute keeps the behaviour
      # and adds what the class never gave: the button stops being submittable and
      # focusable, and `aria-busy` says what the spinner means.
      def button_attributes
        attrs = @options.merge(
          class: class_names(button_classes, @options[:class]),
          type: @type,
          disabled: @disabled || @loading || nil
        )
        attrs[:"aria-busy"] = "true" if @loading
        attrs[:"aria-label"] = @name if responsive_icon_only? && @name.present?
        attrs[:data] = local_overlay_trigger_data(attrs[:data], @modal_options, @drawer_options)
        attrs.compact
      end

      def responsive_icon_only? = @responsive && @icon.present?
    end
  end
end
