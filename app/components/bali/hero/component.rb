# frozen_string_literal: true

module Bali
  module Hero
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :title, ->(text, **options) do
        tag.p(text, **prepend_class_name(options, 'title'))
      end

      renders_one :subtitle, ->(text, **options) do
        tag.p(text, **prepend_class_name(options, 'subtitle'))
      end

      def initialize(size: nil, color: nil, **options)
        @options = prepend_class_name(options, 'hero hero-component')
        @options = prepend_class_name(@options, "is-#{size}") if size
        @options = prepend_class_name(@options, "is-#{color}") if color
      end
    end
  end
end
