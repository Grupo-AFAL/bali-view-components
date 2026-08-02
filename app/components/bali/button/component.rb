# frozen_string_literal: true

module Bali
  module Button
    class Component < ApplicationViewComponent
      # One table for Button, Link and DeleteLink. See Bali::ButtonTaxonomy for
      # why `outline` is a `style:` here and no longer a `variant:`.
      VARIANTS = Bali::ButtonTaxonomy::VARIANTS
      STYLES = Bali::ButtonTaxonomy::STYLES
      SIZES = Bali::ButtonTaxonomy::SIZES

      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }
      renders_one :icon_right, ->(name, **options) { Icon::Component.new(name, **options) }

      # @param variant [Symbol] Colour, from Bali::ButtonTaxonomy::VARIANTS
      # @param style [Symbol] Fill, from Bali::ButtonTaxonomy::STYLES
      # @param size [Symbol] Scale, from Bali::ButtonTaxonomy::SIZES
      # @param type [String, Symbol] The HTML `type` attribute (`:button`, `:submit`,
      #   `:reset`) — never a look. Bali::Link used to take a `type:` that meant the colour,
      #   and it is gone in v3 exactly because of this collision.
      # rubocop:disable Metrics/ParameterLists
      def initialize(name: nil, variant: nil, style: nil, size: nil, icon_name: nil,
                     type: :button, disabled: false, loading: false, responsive: true, **options)
        @name = name
        @variant_class = Bali::ButtonTaxonomy.variant!(self.class, variant)
        @style_class = Bali::ButtonTaxonomy.style!(self.class, style)
        @size_class = Bali::ButtonTaxonomy.size!(self.class, size)
        @icon_name = icon_name
        @type = type
        @disabled = disabled
        @loading = loading
        @responsive = responsive
        @options = options
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def button_classes
        class_names(
          "btn",
          @variant_class,
          @style_class,
          @size_class,
          "btn-disabled" => @disabled,
          "loading loading-spinner" => @loading,
          "max-sm:btn-square" => responsive_icon_only?
        )
      end

      def button_attributes
        attrs = @options.merge(
          class: class_names(button_classes, @options[:class]),
          type: @type,
          disabled: @disabled || nil
        )
        attrs[:"aria-label"] = @name if responsive_icon_only? && @name.present?
        attrs.compact
      end

      def responsive_icon_only? = @responsive && @icon_name.present?
    end
  end
end
