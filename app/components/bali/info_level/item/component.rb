# frozen_string_literal: true

module Bali
  module InfoLevel
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :heading, ->(text = nil, **options, &block) do
          options = prepend_class_name(options, 'heading')

          text.present? ? tag.p(text, **options) : tag.div(**options, &block)
        end

        renders_many :titles, ->(text = nil, **options, &block) do
          options[:class] ||= 'title is-3'

          text.present? ? tag.p(text, **options) : tag.div(**options, &block)
        end

        def initialize(**options)
          @options = prepend_class_name(hyphenize_keys(options), 'level-item is-block')
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
