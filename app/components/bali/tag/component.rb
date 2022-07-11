# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      attr_reader :text, :href, :delete, :size, :skip_confirm

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
        delete: nil,
        **options
      )
        @text = text
        @href = href
        @delete = delete
        @size = size
        @is_grouped = delete.present? && text.to_s.length.positive?
        @addons_options = { class: 'tags has-addons' } if @is_grouped
        @control_options = { class: 'control' } if @is_grouped
        @options = prepend_class_name(options, 'tag-component tag')
        @options = prepend_class_name(@options, 'is-light') if light
        @options = prepend_class_name(@options, "is-#{color}") if color.present?
        @options = prepend_class_name(@options, "is-#{size}") if size.present?
        @options = prepend_class_name(@options, "is-#{type}") if type.present?
        @options = prepend_class_name(@options, 'is-rounded') if rounded
        if @delete.present? && text.to_s.length.zero?
          @options = prepend_class_name(@options,
                                        'is-delete')
        end
        @options = prepend_class_name(@options, 'is-link') if href.present?

        @skip_confirm = @options.delete(:skip_confirm)
        @confirm = @options.delete(:confirm)
        @model = @options.delete(:model)
      end
      # rubocop: enable Metrics/ParameterLists
      # rubocop: enable Metrics/CyclomaticComplexity
      # rubocop: enable Metrics/AbcSize
      # rubocop: enable Metrics/PerceivedComplexity

      def delete_tag
        @tag_options = { class: href.blank? ? 'delete' : 'tag is-delete',
                         href: href,
                         **delete }
        @tag_options = prepend_class_name(@tag_options, "is-#{size}") if size.present?
        @tag_options
      end
    end
  end
end
