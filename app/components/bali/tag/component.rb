# frozen_string_literal: true

module Bali
  module Tag
    class Component < ApplicationViewComponent
      attr_reader :text, :is_delete

      def initialize(
        text: '',
        color: nil,
        is_light: false,
        size: nil,
        type: nil,
        rounded: false,
        is_delete: false,
        **options
      )
        @text = text
        @is_delete = is_delete
        @delete_options = {class: 'delete'}
        @options = prepend_class_name(options, 'tag-item tag')
        @options = prepend_class_name(@options, 'is-light') if is_light
        @options = prepend_class_name(@options, "is-#{color}") if color.present?
        @options = prepend_class_name(@options, "is-#{size}") if size.present?
        @options = prepend_class_name(@options, "is-#{type}") if type.present?
        @options = prepend_class_name(@options, 'is-rounded') if rounded
        @options = prepend_class_name(@options, 'is-delete') if is_delete && text.to_s.length == 0

        @delete_options = prepend_class_name(@delete_options, "is-#{size}") if size.present?
      end
    end
  end
end
