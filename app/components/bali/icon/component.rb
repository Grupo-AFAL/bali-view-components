# frozen_string_literal: true

module Bali
  module Icon
    class Component < ApplicationViewComponent
      include Options

      attr_reader :name, :options

      # @param name [String] One of Bali::Icon::Options::MAP.keys
      def initialize(name, **options)
        @name = name
        @options = prepend_class_name(options, 'icon')
      end

      def call
        tag.span(**options) { icon_svgs(name) }
      end
    end
  end
end
