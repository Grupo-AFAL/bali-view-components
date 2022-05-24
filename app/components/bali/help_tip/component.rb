# frozen_string_literal: true

module Bali
  module HelpTip
    class Component < ApplicationViewComponent
      def initialize(trigger: 'mouseenter focus', placement: 'top', small: false, **options)
        @options = prepend_class_name(
          options,
          class_names('help-tip-component', 'is-small': small)
        )

        @options = prepend_controller(@options, 'help-tip')
        @options['data-help-tip-trigger-value'] = trigger
        @options['data-help-tip-placement-value'] = placement
      end
    end
  end
end
