# frozen_string_literal: true

module Bali
  module Clipboard
    module Source
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'clipboard-source bg-base-200 px-4 py-2 text-sm font-mono ' \
                       'flex items-center min-w-0 flex-1 ' \
                       'rounded-l-lg border border-r-0 border-base-300'

        def initialize(text = '', **options)
          @text = text
          @options = options
        end

        def call
          tag.div(**source_attributes) do
            tag.span(class: 'truncate') do
              text.presence || content
            end
          end
        end

        private

        attr_reader :text, :options

        def source_attributes
          opts = prepend_class_name(options, BASE_CLASSES)
          prepend_data_attribute(opts, 'clipboard-target', 'source')
        end
      end
    end
  end
end
