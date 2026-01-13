# frozen_string_literal: true

module Bali
  module Icon
    class Component < ApplicationViewComponent
      attr_reader :name, :tag_name, :options

      # @param name [String] One of Bali::Icon::Options::MAP.keys
      SIZES = {
        small: 'size-4',
        medium: 'size-8',
        large: 'size-12'
      }.freeze

      def initialize(name, tag_name: :span, size: nil, **options)
        @name = name
        @tag_name = tag_name
        @size = size
        @options = prepend_class_name(options, component_classes)
      end

      def call
        tag.send(tag_name, **options) { Options.find(name) }
      end

      private

      def component_classes
        class_names(
          'icon-component',
          'inline-flex items-center justify-center',
          '*:inline-block *:h-4 *:w-4 *:overflow-visible',
          SIZES[@size],
          size_svg_classes
        )
      end

      def size_svg_classes
        case @size
        when :medium then '*:h-8 *:w-8'
        when :large then '*:h-12 *:w-12'
        end
      end
    end
  end
end
