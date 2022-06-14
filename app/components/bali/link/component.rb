# frozen_string_literal: true

module Bali
  module Link
    class Component < ApplicationViewComponent
      attr_reader :name, :href, :type, :drawer, :modal, :options

      renders_one :icon, ->(name, **options) { Icon::Component.new(name, **options) }

      def initialize(name:, href:, type: nil, modal: false, drawer: false, **options)
        @name = name
        @href = href
        @type = type.present? ? type.to_sym : type
        @modal = modal
        @drawer = drawer
        @options = options
        @options = prepend_class_name(@options, "button is-#{type}") if type.present?
        @options = prepend_action(@options, 'modal#open') if modal
        @options = prepend_action(@options, 'drawer#open') if drawer
      end
    end
  end
end
