# frozen_string_literal: true

module Bali
  module Link
    class Component < ApplicationViewComponent
      attr_reader :name, :href, :type, :drawer, :modal, :options

      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }

      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/AbcSize
      def initialize(name:, href:, type: nil, modal: false, drawer: false, active_path: nil,
                     match: :exact, method: nil, **options)
        @name = name
        @href = href
        @type = type.present? ? type.to_sym : type
        @modal = modal
        @active_path = active_path
        @drawer = drawer
        @method = method
        @options = options
        active_link(href, active_path, match: match) if active_path.present?
        @options = prepend_class_name(@options, "button is-#{type}") if type.present?
        @options = prepend_action(@options, 'modal#open') if modal
        @options = prepend_action(@options, 'drawer#open') if drawer
        @options = prepend_turbo_method(@options, method.to_s) if method.present?
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/ParameterLists

      def active_link(href, current_path, match: :exact)
        @options = prepend_class_name(@options, 'is-active') if active_path?(href, current_path,
                                                                             match: match)
      end
    end
  end
end
