# frozen_string_literal: true

module Bali
  module Clipboard
    module SucessContent
      class Component < ApplicationViewComponent
        attr_reader :text, :options

        def initialize(text = '', **options)
          @text = text

          @options = prepend_class_name(options, 'clipboard-sucess-content')
          @options = prepend_data_attribute(@options, 'clipboard-target', 'successContent')
          @options = prepend_class_name(@options, 'hidden')
        end

        def call
          return tag.div(text, **options) if text.present?

          tag.div(**options) { content }
        end
      end
    end
  end
end
