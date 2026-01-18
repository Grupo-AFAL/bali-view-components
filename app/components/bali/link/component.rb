# frozen_string_literal: true

module Bali
  module Link
    class Component < ApplicationViewComponent
      VARIANTS = {
        primary: 'btn-primary',
        secondary: 'btn-secondary',
        accent: 'btn-accent',
        info: 'btn-info',
        success: 'btn-success',
        warning: 'btn-warning',
        error: 'btn-error',
        ghost: 'btn-ghost',
        link: 'btn-link',
        neutral: 'btn-neutral'
      }.freeze

      SIZES = {
        xs: 'btn-xs',
        sm: 'btn-sm',
        md: '',
        lg: 'btn-lg',
        xl: 'btn-xl'
      }.freeze

      attr_reader :name, :href, :icon_name

      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }
      renders_one :icon_right, ->(name, **options) { Icon::Component.new(name, **options) }

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        href:,
        name: nil,
        variant: nil,
        size: nil,
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
        type: nil, # DEPRECATED: Use `variant` instead
        **options
      )
        # rubocop:enable Metrics/ParameterLists
        @name = name
        @href = href
        # Support deprecated `type` parameter for backwards compatibility
        @variant = (variant || type)&.to_sym
        @size = size&.to_sym
        @icon_name = icon_name
        @active = active
        @active_path = active_path
        @match = match
        @method = method
        @disabled = disabled
        @plain = plain
        @modal = modal
        @drawer = drawer
        @authorized = authorized
        @options = options
      end

      def render?
        @authorized
      end

      def link_classes
        class_names(
          base_class,
          variant_class,
          size_class,
          @options[:class],
          { 'active' => active?, 'btn-disabled' => @disabled && button_style? }
        )
      end

      def link_attributes
        attrs = @options.except(:class)
        attrs[:href] = @href unless @disabled
        attrs[:disabled] = true if @disabled
        attrs[:data] = build_data_attributes(attrs[:data])
        attrs.compact
      end

      private

      attr_reader :options

      def base_class
        if button_style?
          'btn'
        elsif @plain
          'flex items-center gap-2'
        else
          'link inline-flex items-center gap-1'
        end
      end

      def variant_class
        VARIANTS[@variant] if button_style?
      end

      def size_class
        SIZES[@size] if button_style? && @size
      end

      def button_style?
        @variant.present?
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

        data[:action] = prepend_value(data[:action], 'modal#open') if @modal
        data[:action] = prepend_value(data[:action], 'drawer#open') if @drawer
      end

      def add_method_attributes(data)
        return if @method.blank?

        if @method.to_s == 'get'
          data[:method] = 'get'
        else
          data[:turbo_method] = @method.to_s
        end
      end

      def prepend_value(existing, new_value)
        [new_value, existing].compact.join(' ')
      end
    end
  end
end
