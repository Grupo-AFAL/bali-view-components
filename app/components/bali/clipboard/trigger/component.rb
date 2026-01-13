# frozen_string_literal: true

module Bali
  module Clipboard
    module Trigger
      class Component < ApplicationViewComponent
        attr_reader :text, :options

        def initialize(text = '', **options)
          @text = text

          @options = prepend_class_name(options, 'clipboard-trigger cursor-pointer border rounded-r-md px-3 py-2 border-base-300')
          @options = prepend_data_attribute(@options, 'clipboard-target', 'button')
          @options = prepend_action(@options, 'click->clipboard#copy')
          @options[:type] = :button
        end

        def call
          return tag.button(text, **options) if text.present?

          tag.button(**options) { content }
        end
      end
    end
  end
end
