# frozen_string_literal: true

module Bali
  module Message
    class Component < ApplicationViewComponent
      attr_reader :title, :options

      renders_one :header

      def initialize(title: nil, size: :medium, color: :primary, **options)
        @title = title
        @options = prepend_class_name(options, 'message message-component')
        @options = prepend_class_name(options, "is-#{size} is-#{color}")
      end
    end
  end
end
