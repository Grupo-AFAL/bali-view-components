# frozen_string_literal: true

module Bali
  module InfoLevel
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :heading, ->(**options, &block) do
          options = prepend_class_name(options, 'heading')
          tag.p(**options, &block)
        end

        renders_many :titles, ->(**options, &block) do
          options[:class] = 'title is-3' unless options[:class]
          tag.p(**options, &block)
        end

        def initialize(**options)
          @options = prepend_class_name(hyphenize_keys(options), 'level-item has-text-centered')
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
