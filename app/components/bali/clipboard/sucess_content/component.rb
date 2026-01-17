# frozen_string_literal: true

module Bali
  module Clipboard
    module SucessContent
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'clipboard-sucess-content hidden text-success'

        def initialize(text = '', **options)
          @text = text
          @options = options
        end

        def call
          tag.span(**success_attributes) do
            text.presence || content
          end
        end

        private

        attr_reader :text, :options

        def success_attributes
          opts = prepend_class_name(options, BASE_CLASSES)
          prepend_data_attribute(opts, 'clipboard-target', 'successContent')
        end
      end
    end
  end
end
