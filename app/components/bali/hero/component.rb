# frozen_string_literal: true

module Bali
  module Hero
    class Component < ApplicationViewComponent
      SIZES = {
        sm: 'min-h-48',
        md: 'min-h-80',
        lg: 'min-h-screen'
      }.freeze

      COLORS = {
        base: 'bg-base-200',
        primary: 'bg-primary text-primary-content',
        secondary: 'bg-secondary text-secondary-content',
        accent: 'bg-accent text-accent-content',
        neutral: 'bg-neutral text-neutral-content'
      }.freeze

      renders_one :title, ->(text, **options) do
        tag.h1(text, **prepend_class_name(options, 'text-5xl font-bold'))
      end

      renders_one :subtitle, ->(text, **options) do
        tag.p(text, **prepend_class_name(options, 'py-4'))
      end

      def initialize(size: :md, color: :base, centered: true, **options)
        @size = size.to_sym
        @color = color.to_sym
        @centered = centered
        @options = options
      end

      def hero_classes
        class_names(
          'hero',
          SIZES.fetch(@size, SIZES[:md]),
          COLORS.fetch(@color, COLORS[:base]),
          @options[:class]
        )
      end

      def content_classes
        class_names(
          'hero-content',
          @centered && 'text-center'
        )
      end

      private

      attr_reader :size, :color, :centered, :options
    end
  end
end
