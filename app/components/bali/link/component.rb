# frozen_string_literal: true

module Bali
  module Link
    class Component < ApplicationViewComponent
      attr_reader :name, :href, :type, :drawer, :modal, :options

      renders_one :icon, ->(**options, &block) { tag.span(**options, &block) }

      def initialize(name:, href:, type: :normal, modal: false, drawer: false, **options)
        @name = name
        @href = href
        @type = type.to_sym
        @modal = modal
        @drawer = drawer
        @data = hyphenize_keys((options.delete(:data) || {}))
        @options = prepend_class_name(options, "button is-#{type}")
      end

      def data
        @data.merge!(action: 'remote-modal#open') if modal
        @data.merge!(action: 'remote-drawer#open') if drawer

        @data
      end
    end
  end
end
