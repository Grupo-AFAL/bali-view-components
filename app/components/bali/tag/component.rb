# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      attr_reader :text, :href, :is_delete

      def initialize(
        text: '',
        href: nil,
        color: nil,
        is_light: false,
        size: nil,
        type: nil,
        rounded: false,
        is_delete: false,
        **options
      )
        @text = text
        @href = href
        @is_delete = is_delete
        @is_grouped = is_delete && text.to_s.length > 0
        @delete_options = {class: href.blank? ? 'delete' : 'tag is-delete'}
        @addons_options = {class: @is_grouped ? 'tags has-addons' : ''}
        @control_options = {class: @is_grouped ? 'control' : ''}
        @options = prepend_class_name(options, 'tag-item tag')
        @options = prepend_class_name(@options, 'is-light') if is_light
        @options = prepend_class_name(@options, "is-#{color}") if color.present?
        @options = prepend_class_name(@options, "is-#{size}") if size.present?
        @options = prepend_class_name(@options, "is-#{type}") if type.present?
        @options = prepend_class_name(@options, 'is-rounded') if rounded
        @options = prepend_class_name(@options, 'is-delete') if is_delete && text.to_s.length == 0
        @options = prepend_class_name(@options, 'is-link') if href.present?

        @delete_options = prepend_class_name(@delete_options, "is-#{size}") if size.present?
      end
    end
  end
end
