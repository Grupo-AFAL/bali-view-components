# frozen_string_literal: true

module Bali
  module Tooltip
    class Component < ApplicationViewComponent
      renders_one :trigger

      def initialize(trigger: 'mouseenter focus', placement: 'top', small: false, **options)
        @options = prepend_class_name(
          options,
          class_names('tooltip-component', 'is-small': small)
        )

        @options = prepend_controller(@options, 'tooltip')
        @options = prepend_values(@options, 'tooltip', { trigger: trigger, placement: placement })
      end
    end
  end
end
