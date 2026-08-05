# frozen_string_literal: true

module Bali
  module Link
    class Component < ApplicationViewComponent
      include Bali::DeprecatedIconName

      # One table for Button, Link and DeleteLink. See Bali::ButtonTaxonomy.
      VARIANTS = Bali::ButtonTaxonomy::VARIANTS
      SIZES = Bali::ButtonTaxonomy::SIZES
      STYLES = Bali::ButtonTaxonomy::STYLES

      # `type:` named the colour here and the HTML attribute in Bali::Button, which is why
      # it is gone rather than renamed. Rejected rather than dropped: `<a type="ghost">` is
      # valid HTML, so **options would have quietly turned it into an attribute.
      TYPE_REMOVED_MESSAGE = "Bali::Link::Component no longer accepts `type:`. " \
                             "Use `variant:` for the colour (`type:` was deprecated in v2.0)."

      attr_reader :name, :href

      # The slot and the `icon:` keyword are the same concept written two ways, and now
      # under the same word: the slot is the one that takes options (`with_icon('star',
      # class: 'text-error')`), so it wins when both are given.
      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }
      renders_one :icon_right, ->(name, **options) { Icon::Component.new(name, **options) }

      # @param icon [String, Symbol] Icon name, drawn before the label.
      # @param icon_name [String, nil] @deprecated Removed in Bali 4.0. Use `icon:`.
      # rubocop:disable Metrics/ParameterLists
      def initialize(
        href:,
        name: nil,
        variant: nil,
        style: nil,
        size: nil,
        icon: nil,
        icon_name: nil,
        active: nil,
        active_path: nil,
        match: :exact,
        method: nil,
        disabled: false,
        plain: false,
        modal: false,
        drawer: false,
        authorized: true,
        responsive: true,
        **options
      )
        # rubocop:enable Metrics/ParameterLists
        reject_type!(options)

        @name = name
        @href = href
        @variant = variant&.to_sym
        @style = style&.to_sym
        @size = size&.to_sym
        @variant_class = Bali::ButtonTaxonomy.variant!(self.class, variant)
        @style_class = Bali::ButtonTaxonomy.style!(self.class, style)
        @size_class = Bali::ButtonTaxonomy.size!(self.class, size)
        @icon = icon || deprecated_icon_name(icon_name)
        @active = active
        @active_path = active_path
        @match = match
        @method = method
        @disabled = disabled
        @plain = plain
        @modal = modal
        @modal_options = normalize_options(modal)
        @drawer = drawer
        @drawer_options = normalize_options(drawer)
        @authorized = authorized
        @responsive = responsive
        @options = options
      end

      def render?
        @authorized
      end

      def authorized?
        @authorized
      end

      def link_classes
        class_names(
          base_class,
          variant_class,
          style_class,
          size_class,
          @options[:class],
          "active" => active?,
          "btn-disabled" => @disabled && button_style?,
          "max-sm:btn-square" => responsive_icon_only?
        )
      end

      def link_attributes
        attrs = @options.except(:class)
        attrs[:href] = @href unless @disabled
        attrs[:disabled] = true if @disabled
        attrs[:data] = build_data_attributes(attrs[:data])
        attrs[:"aria-label"] = @name if responsive_icon_only? && @name.present?
        attrs.compact
      end

      private

      attr_reader :options

      def reject_type!(options)
        return unless options.key?(:type)

        raise ArgumentError, TYPE_REMOVED_MESSAGE
      end

      def base_class
        if button_style?
          "btn"
        elsif @plain
          "flex items-center gap-2"
        else
          "link inline-flex items-center gap-1"
        end
      end

      def variant_class
        @variant_class if button_style?
      end

      def size_class
        @size_class if button_style?
      end

      def style_class
        @style_class if button_style?
      end

      def button_style?
        @variant.present? || @style.present?
      end

      def active?
        return @active unless @active.nil?

        active_path?(@href, @active_path, match: @match)
      end

      def build_data_attributes(existing_data)
        data = existing_data&.dup || {}
        add_stimulus_actions(data)
        add_method_attributes(data)
        data.presence
      end

      def add_stimulus_actions(data)
        return if Bali.native_app || @disabled

        if modal_enabled?
          data[:action] = prepend_value(data[:action], "modal#open")
          data[:turbo] = false # Prevent Turbo Drive from also handling the click
          data[:modal_size] = @modal_options[:size] if @modal_options[:size]
        end

        return unless drawer_enabled?

        data[:action] = prepend_value(data[:action], "drawer#open")
        data[:turbo] = false # Prevent Turbo Drive from also handling the click
        data[:drawer_size] = @drawer_options[:size] if @drawer_options[:size]
      end

      def add_method_attributes(data)
        return if @method.blank?

        if @method.to_s == "get"
          data[:method] = "get"
        else
          data[:turbo_method] = @method.to_s
        end
      end

      def prepend_value(existing, new_value)
        [ new_value, existing ].compact.join(" ")
      end

      def modal_enabled? = @modal.present?
      def drawer_enabled? = @drawer.present?
      def responsive_icon_only? = @responsive && button_style? && @icon.present?

      # Normalize option to hash format. Supports: true, { size: :lg }
      def normalize_options(value) = value.is_a?(Hash) ? value.symbolize_keys : {}
    end
  end
end
