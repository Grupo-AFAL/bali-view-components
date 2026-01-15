# frozen_string_literal: true

module Bali
  module List
    module Item
      class Component < ApplicationViewComponent
        attr_reader :options

        TITLE_CLASSES = 'title text-base font-semibold'
        SUBTITLE_CLASSES = 'subtitle text-sm text-base-content/60'
        ITEM_CLASSES = 'list-item-component flex items-center justify-between gap-4 ' \
                       'py-2 px-4 border-b border-base-300 last:border-b-0'

        renders_one :title, ->(text = nil, **options, &block) do
          tag.div(text || block.call, **prepend_class_name(options, TITLE_CLASSES))
        end

        renders_one :subtitle, ->(text = nil, **options, &block) do
          tag.div(text || block.call, **prepend_class_name(options, SUBTITLE_CLASSES))
        end

        renders_many :actions

        def initialize(**options)
          @options = prepend_class_name(options, ITEM_CLASSES)
        end
      end
    end
  end
end
