# frozen_string_literal: true

module Bali
  module PageHeader
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :right_panel

      renders_one :title, ->(text, **options) do
        options[:class] ||= 'title is-1'
        tag.h1 text, **options
      end

      renders_one :subtitle, ->(text, **options) do
        options[:class] ||= 'subtitle mt-0 is-6'
        tag.p text, **options
      end

      def initialize(**options)
        @options = prepend_class_name(options, 'page-header-component')
      end
    end
  end
end
