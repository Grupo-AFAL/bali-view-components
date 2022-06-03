# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :title, ->(text = nil, **options, &block) do
        options[:class] ||= 'title is-1 mb-0'
        text.present? ? tag.h1(text, **options) : tag.div(&block)
      end

      renders_one :subtitle, ->(text = nil, **options, &block) do
        options[:class] ||= 'subtitle mt-0 is-6'
        text.present? ? tag.p(text, **options) : tag.div(&block)
      end

      def initialize(title: nil, subtitle: nil, **options)
        @title = title
        @subtitle = subtitle
        @options = prepend_class_name(options, 'page-header-component')
      end
    end
  end
end
