# frozen_string_literal: true

module Bali
  module Link
    class Component < ApplicationViewComponent
      COLORS = {
        primary: 'btn-primary',
        secondary: 'btn-secondary',
        accent: 'btn-accent',
        info: 'btn-info',
        success: 'btn-success',
        warning: 'btn-warning',
        error: 'btn-error',
        danger: 'btn-error',
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

      attr_reader :name, :href, :type, :icon_name, :drawer, :modal, :options

      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }
      renders_one :icon_right, ->(name, **options) { Icon::Component.new(name, **options) }

      # rubocop:disable Metrics/ParameterLists
      def initialize(href:,
                     name: nil,
                     type: nil,
                     size: nil,
                     icon_name: nil,
                     modal: false,
                     drawer: false,
                     active_path: nil,
                     active: nil,
                     match: :exact,
                     method: nil,
                     disabled: false,
                     plain: false,
                     **options)
        @name = name
        @href = href
        @type = type&.to_sym
        @size = size&.to_sym
        @icon_name = icon_name
        @modal = modal
        @active_path = active_path
        @active = active
        @drawer = drawer
        @method = method
        @plain = plain
        @options = options

        @authorized = @options.key?(:authorized) ? @options.delete(:authorized) : true

        build_options(disabled, match)
      end
      # rubocop:enable Metrics/ParameterLists

      def render?
        authorized?
      end

      def authorized?
        @authorized
      end

      private

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def build_options(disabled, match)
        if disabled
          @options[:disabled] = true
          @options = prepend_class_name(@options, 'btn-disabled') if @type.present?
        else
          @options[:href] = @href
        end

        if @active == true || (@active.nil? && active_path?(@href, @active_path, match: match))
          @options = prepend_class_name(@options, 'active')
        end

        if @type.present?
          @options = prepend_class_name(@options, 'btn')
          @options = prepend_class_name(@options, COLORS[@type]) if COLORS[@type]
          @options = prepend_class_name(@options, SIZES[@size]) if @size && SIZES[@size]
        elsif @plain
          # Minimal layout classes for menu items (icons + text need flex)
          @options = prepend_class_name(@options, 'flex items-center gap-2')
        else
          @options = prepend_class_name(@options, 'link inline-flex items-center gap-1')
        end

        unless Bali.native_app
          @options = prepend_action(@options, 'modal#open') if @modal && !disabled
          @options = prepend_action(@options, 'drawer#open') if @drawer && !disabled
        end

        if @method.to_s == 'get'
          @options = prepend_data_attribute(@options, :method, 'get')
        elsif @method.present?
          @options = prepend_turbo_method(@options, @method.to_s)
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end
