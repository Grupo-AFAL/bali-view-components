# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      attr_reader :text, :href, :delete, :size

      # rubocop: disable Metrics/ParameterLists
      # rubocop: disable Metrics/CyclomaticComplexity
      # rubocop: disable Metrics/AbcSize
      # rubocop: disable Metrics/PerceivedComplexity
      def initialize(
        text: '',
        href: nil,
        color: nil,
        light: false,
        size: nil,
        type: nil,
        rounded: false,
        delete: false,
        **options
      )
        @text = text
        @href = href
        @delete = delete
        @size = size
        @is_grouped = delete && text.to_s.length.positive?
        @addons_options = { class: 'tags has-addons' } if @is_grouped
        @control_options = { class: 'control' } if @is_grouped
        @options = prepend_class_name(options, 'tag-component tag')
        @options = prepend_class_name(@options, 'is-light') if light
        @options = prepend_class_name(@options, "is-#{color}") if color.present?
        @options = prepend_class_name(@options, "is-#{size}") if size.present?
        @options = prepend_class_name(@options, "is-#{type}") if type.present?
        @options = prepend_class_name(@options, 'is-rounded') if rounded
        @options = prepend_class_name(@options, 'is-delete') if delete && text.to_s.length.zero?
        @options = prepend_class_name(@options, 'is-link') if href.present?

      end
      # rubocop: enable Metrics/ParameterLists
      # rubocop: enable Metrics/CyclomaticComplexity
      # rubocop: enable Metrics/AbcSize
      # rubocop: enable Metrics/PerceivedComplexity

      def delete_button
        @delete_options = { class: href.blank? ? 'delete' : 'tag is-delete', data: {} }
        @delete_options = prepend_class_name(@delete_options, "is-#{size}") if size.present?
        @delete_options
      end
    end
  end
end
