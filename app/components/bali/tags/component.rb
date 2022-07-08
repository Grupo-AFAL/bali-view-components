# frozen_string_literal: true

module Bali
  module Tags
    class Component < ApplicationViewComponent
      renders_many :tag_items, ->(text: nil, href: nil, is_delete: false, **options) do
        @with_links = true if is_delete && text.to_s.length > 0 && href.present?
        size = @all_sizes || nil
        Bali::Tag::Component.new(
          text: text,
          href: href,
          is_delete: is_delete,
          is_light: @all_light,
          rounded: @all_rounded,
          size: size,
          **options
        )
      end

      def initialize(
        sizes: nil,
        all_light: false,
        all_rounded: false,
        **options
      )
        @with_links = false
        @all_light = all_light
        @all_rounded = all_rounded
        @all_sizes = sizes
        @options = prepend_class_name(options, 'tags-component')
        @options = prepend_class_name(@options, "are-#{sizes}") if sizes.present?
      end

      def container_options
        @options = prepend_class_name(@options, @with_links ? 'field is-grouped is-grouped-multiline' : 'tags')
      end
    end
  end
end
