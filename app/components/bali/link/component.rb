# frozen_string_literal: true

module Bali
  module Link
    class Component < ApplicationViewComponent
      attr_reader :name, :href, :type, :icon_name, :drawer, :modal, :options

      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }
      renders_one :icon_right, ->(name, **options) { Icon::Component.new(name, **options) }

      # @param name [String] The name of the link.
      # @param href [String] The href of the link.
      # @param type [Symbol|String] This adds a class for the link: :primary, :secondary,
      #  :success, :danger, :warning also adds the button class.
      # @param modal [Boolean] Link to open a modal.
      # @param drawer [Boolean] Link to open a drawer.
      # @param active_path [String] The path of the active page.
      # @param match [Symbol] To check if the path is exact or cotains the path.
      # @param method [Symbol|String] Adds a turbo method to the link.

      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      # rubocop: disable Metrics/AbcSize
      def initialize(href:,
                     name: nil,
                     type: nil,
                     icon_name: nil,
                     modal: false,
                     drawer: false,
                     active_path: nil,
                     active: nil,
                     match: :exact,
                     method: nil,
                     disabled: false,
                     **options)

        @name = name
        @href = href
        @type = type
        @icon_name = icon_name
        @modal = modal
        @active_path = active_path
        @active = active
        @drawer = drawer
        @method = method
        @options = options
        @options = prepend_class_name(@options, 'link-component')

        if disabled
          @options[:disabled] = true
        else
          @options[:href] = href
        end

        if @active == true || (@active.nil? && active_path?(href, active_path, match: match))
          @options = prepend_class_name(@options, 'is-active')
        end

        @options = prepend_class_name(@options, "button is-#{type}") if type.present?

        unless Bali.native_app
          @options = prepend_action(@options, 'modal#open') if modal && !disabled
          @options = prepend_action(@options, 'drawer#open') if drawer && !disabled
        end

        if method.to_s == 'get'
          @options = prepend_data_attribute(@options, :method, 'get')
        elsif method.present?
          @options = prepend_turbo_method(@options, method.to_s)
        end
      end
      # rubocop: enable Metrics/AbcSize
      # rubocop:enable Metrics/ParameterLists
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
    end
  end
end
