# frozen_string_literal: true

module Bali
  module Tags
    class Component < ApplicationViewComponent

      renders_many :tag_items, -> (**options) do
        TagItem::Component.new(
          is_light: @all_light,
          rounded: @all_rounded,
          **options
        )
      end

      def initialize(
        sizes: nil,
        all_light: false,
        all_rounded: false,
        **options
      )
        @all_light = all_light
        @all_rounded = all_rounded
        @options = prepend_class_name(options, 'tags-component tags')
        @options = prepend_class_name(@options, "are-#{sizes}") if sizes.present?
      end
    end
  end
end
