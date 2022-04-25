# frozen_string_literal: true

module Bali
  module Modal
    class Component < ApplicationViewComponent
      def initialize(active: true, **options)
        @active = active
        @options = options
      end

      def classes
        class_names('modal-component', @options[:class])
      end
    end
  end
end
