# frozen_string_literal: true

module Bali
  module InfoLevel
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :heading, ->(text = nil, **options, &block) do
          heading_classes = 'heading text-xs text-base-content/60 uppercase tracking-wide'
          options = prepend_class_name(options, heading_classes)

          text.present? ? tag.p(text, **options) : tag.div(**options, &block)
        end

        renders_many :titles, ->(text = nil, **options, &block) do
          options[:class] ||= 'title text-2xl font-bold'

          text.present? ? tag.p(text, **options) : tag.div(**options, &block)
        end

        def initialize(**options)
          @options = prepend_class_name(hyphenize_keys(options), 'level-item text-center')
        end

        def call
          tag.div(**options) do
            safe_join([heading, titles])
          end
        end
      end
    end
  end
end
