# frozen_string_literal: true

module Bali
  module List
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        renders_one :title, ->(text = nil, **options, &block) do
          tag.div(text || block.call, **prepend_class_name(options, 'title is-6'))
        end

        renders_one :subtitle, ->(text = nil, **options, &block) do
          tag.div(text || block.call, **prepend_class_name(options, 'subtitle is-7'))
        end

        renders_many :actions

        def initialize(**options)
          @options = prepend_class_name(options, 'list-item-component')
        end
      end
    end
  end
end
