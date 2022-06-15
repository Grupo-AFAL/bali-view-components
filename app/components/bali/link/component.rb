# frozen_string_literal: true

module Bali
  module Link
    class Component < ApplicationViewComponent
      attr_reader :name, :href, :type, :drawer, :modal, :options

      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }

      # Params:
      #  name: [String] The name of the link.
      #  href: [String] The href of the link.
      #  type: [Symbol] or [String] This is a class for the link:
      #   (:primary, :secondary, :success, :danger, :warning)

      #  modal: [Boolean] The link opens a modal.
      #  drawer: [Boolean] The link opens a drawer.
      #  active_path: [String] The path of the active page.
      #  match: [Symbol] To check if the path is exact or cotains the path.
      #  method: [Symbol] or [String] The method to call when the link is clicked.

      # rubocop:disable Metrics/ParameterLists
      # rubocop:disable Metrics/AbcSize
      def initialize(name:,
                     href:,
                     type: nil,
                     modal: false,
                     drawer: false,
                     active_path: nil,
                     match: :exact,
                     method: nil,
                     **options)

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
