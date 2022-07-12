# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      attr_reader :text, :href, :options

      # rubocop: disable Metrics/ParameterLists
      def initialize(
        text:,
        href: nil,
        color: nil,
        size: nil,
        light: false,
        rounded: false,
        **options
      )
        @text = text
        @href = href

        options[:href] = href if href.present?
        @options = prepend_class_name(options, 'tag-component tag')
        @options = prepend_class_name(@options, "is-#{color}") if color.present?
        @options = prepend_class_name(@options, "is-#{size}") if size.present?
        @options = prepend_class_name(@options, 'is-light') if light
        @options = prepend_class_name(@options, 'is-rounded') if rounded
      end
      # rubocop: enable Metrics/ParameterLists

      def tag_name
        href.present? ? :a : :div
      end
    end
  end
end
