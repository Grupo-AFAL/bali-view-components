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
          '[&_.svg-inline]:inline-block [&_.svg-inline]:text-[1em] [&_.svg-inline]:h-4 [&_.svg-inline]:w-4 [&_.svg-inline]:overflow-visible [&_.svg-inline]:align-[-0.125em]',
          SIZES[@size],
          size_svg_classes
        )
      end

      def size_svg_classes
        case @size
        when :medium then '[&_.svg-inline]:h-8 [&_.svg-inline]:w-8'
        when :large then '[&_.svg-inline]:h-12 [&_.svg-inline]:w-12'
        end
      end
    end
  end
end
