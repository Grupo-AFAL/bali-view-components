# frozen_string_literal: true

module Bali
  module Clipboard
    module Source
      class Component < ApplicationViewComponent
        attr_reader :text, :options

        def initialize(text = '', **options)
          @text = text

          @options = prepend_class_name(
            options,
            'clipboard-source border border-r-0 rounded-l-md px-2 py-2 pr-16 border-base-300'
          )
          @options = prepend_data_attribute(@options, 'clipboard-target', 'source')
        end

        def call
          return tag.div(text, **options) if text.present?

          tag.div(**options) { content }
        end
      end
    end
  end
end
