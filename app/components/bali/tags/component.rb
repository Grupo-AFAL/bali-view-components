# frozen_string_literal: true

module Bali
  module Tags
    class Component < ApplicationViewComponent

      def initialize(, **options)
        @options = prepend_class_name(options, 'tags-component')
      end
    end
  end
end
