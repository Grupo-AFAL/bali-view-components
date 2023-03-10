# frozen_string_literal: true

module Bali
  module SwappableIcons
    class Component < ApplicationViewComponent
      attr_reader :options

      renders_one :main_icon, ->(name, **options) do
        Icon::Component.new(name, **prepend_class_name(options || {}, 'main-icon'))
      end
      renders_one :secondary_icon, ->(name, **options) do
        Icon::Component.new(name, **prepend_class_name(options || {}, 'secondary-icon'))
      end

      def initialize(**options)
        @options = prepend_class_name(options, 'swappable-icons-component')
      end
    end
  end
end
