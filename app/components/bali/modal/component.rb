# frozen_string_literal: true

module Bali
  module Modal
    class Component < ApplicationViewComponent
      def initialize(active: true, **options)
        @active = active
        @wrapper_class = options.delete(:wrapper_class)
        @options = prepend_class_name(options, 'is-active') if @active
        @options = prepend_class_name(options, 'modal-component modal')
      end
    end
  end
end
