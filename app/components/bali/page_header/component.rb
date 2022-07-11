# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :title, ->(text = nil, type: :h3, **options, &block) do
        options = prepend_class_name(options, class_names('title', heading_size_class(type)))

        heading_tag(text, type, **options, &block)
      end

      renders_one :subtitle, ->(text = nil, type: :h5, **options, &block) do
        options = prepend_class_name(options, class_names('subtitle', heading_size_class(type)))

        heading_tag(text, type, **options, &block)
      end

      def initialize(title: nil, subtitle: nil, **options)
        @title = title
        @subtitle = subtitle
        @options = prepend_class_name(options, 'page-header-component')
      end

      def heading_size_class(type)
        {
          'is-1': type == :h1,
          'is-2': type == :h2,
          'is-3': type == :h3,
          'is-4': type == :h4,
          'is-5': type == :h5,
          'is-6': type == :h6
        }
      end

      def heading_tag(text, type, **options, &)
        size = type.to_s.gsub(/^h/, '')

        text.present? ? tag.send("h#{size}", text, **options) : tag.div(&)
      end
    end
  end
end
