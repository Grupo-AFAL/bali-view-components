# frozen_string_literal: true

module Bali
  module InfoLevel
    module Item
      class Component < ApplicationViewComponent
        BASE_CLASSES = 'level-item text-center'
        HEADING_CLASSES = 'heading text-xs text-base-content/60 uppercase tracking-wide'
        TITLE_CLASSES = 'title text-2xl font-bold'

        renders_one :heading, ->(text = nil, **options, &block) do
          options = prepend_class_name(options, HEADING_CLASSES)
          text.present? ? tag.p(text, **options) : tag.div(**options, &block)
        end

        renders_many :titles, ->(text = nil, **options, &block) do
          options = prepend_class_name(options, TITLE_CLASSES)
          text.present? ? tag.p(text, **options) : tag.div(**options, &block)
        end

        def initialize(**options)
          @options = prepend_class_name(hyphenize_keys(options), BASE_CLASSES)
        end

        def call
          tag.div(**options) do
            safe_join([heading, titles])
          end
        end

        private

        attr_reader :options
      end
    end
  end
end
