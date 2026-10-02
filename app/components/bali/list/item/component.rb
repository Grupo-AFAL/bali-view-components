# frozen_string_literal: true

module Bali
  module List
    module Item
      class Component < ApplicationViewComponent
        BASE_CLASSES = "list-row"
        TITLE_CLASSES = "font-semibold"
        # `/70`, not `/60`: at 14px `/60` measured 4.04:1 on `afal`, under AA's 4.5:1.
        SUBTITLE_CLASSES = "text-sm text-base-content/70"
        CONTENT_CLASSES = "list-col-grow"
        ACTIONS_CLASSES = "flex items-center gap-2 ml-auto"

        renders_one :title, ->(text = nil, **options, &block) do
          tag.div(text || block&.call, **prepend_class_name(options, TITLE_CLASSES))
        end

        renders_one :subtitle, ->(text = nil, **options, &block) do
          tag.div(text || block&.call, **prepend_class_name(options, SUBTITLE_CLASSES))
        end

        renders_many :actions

        def initialize(**options)
          @options = options
        end

        private

        attr_reader :options

        def item_options
          prepend_class_name(options, BASE_CLASSES)
        end
      end
    end
  end
end
