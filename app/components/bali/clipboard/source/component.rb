# frozen_string_literal: true

module Bali
  module Clipboard
    module Source
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'clipboard-source input input-bordered rounded-r-none pr-16 join-item'

        def initialize(text = '', **options)
          @text = text
          @options = options
        end

        def call
          tag.div(**source_attributes) do
            text.presence || content
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
