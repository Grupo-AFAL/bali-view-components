# frozen_string_literal: true

module Bali
  module Icon
    class Component < ApplicationViewComponent
      include Options

      attr_reader :name, :tag_name, :options

      # @param name [String] One of Bali::Icon::Options::MAP.keys
      def initialize(name, tag_name: :span, **options)
        @name = name
        @tag_name = tag_name
        @options = prepend_class_name(options, 'icon-component icon')
      end

      def call
        tag.send(tag_name, **options) { icon_svgs(name) }
      end
    end
  end
end
