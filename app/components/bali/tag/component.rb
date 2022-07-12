# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      attr_reader :text, :href, :size, :skip_confirm

      # rubocop: disable Metrics/ParameterLists
      def initialize(
        text: '',
        href: nil,
        color: nil,
        light: false,
        size: nil,
        type: nil,
        rounded: false,
        **options
      )
        @text = text
        @href = href
        @size = size
        @options = prepend_class_name(options, 'tag-component tag')
        @options = prepend_class_name(@options, 'is-light') if light
        @options = prepend_class_name(@options, "is-#{color}") if color.present?
        @options = prepend_class_name(@options, "is-#{size}") if size.present?
        @options = prepend_class_name(@options, "is-#{type}") if type.present?
        @options = prepend_class_name(@options, 'is-rounded') if rounded

        @options = prepend_class_name(@options, 'is-link') if href.present?
      end
      # rubocop: enable Metrics/ParameterLists
    end
  end
end
