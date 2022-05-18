# frozen_string_literal: true

module Bali
  module InfoLevel
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :heading, ->(text, **options) do
          options = prepend_class_name(options, 'heading')
          tag.p(text, **options)
        end

        renders_many :titles, ->(text, **options) do
          options[:class] ||= 'title is-3'
          tag.p(text, **options)
        end

        def initialize(**options)
          @options = prepend_class_name(
            hyphenize_keys(options), 'level-item has-text-centered is-block'
          )
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
