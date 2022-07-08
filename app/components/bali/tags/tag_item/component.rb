# frozen_string_literal: true

module Bali
  module Tags
    module TagItem
      class Component < ApplicationViewComponent

        attr_reader :text

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
          text = '' if is_delete
          @text = text
          @options = prepend_class_name(options, 'tag-item tag')
          @options = prepend_class_name(@options, 'is-light') if is_light
          @options = prepend_class_name(@options, "is-#{color}") if color.present?
          @options = prepend_class_name(@options, "is-#{size}") if size.present?
          @options = prepend_class_name(@options, "is-#{type}") if type.present?
          @options = prepend_class_name(@options, 'is-rounded') if rounded
          @options = prepend_class_name(@options, 'is-delete') if is_delete
        end
      end
    end
  end
end
