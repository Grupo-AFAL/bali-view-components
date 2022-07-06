# frozen_string_literal: true

module Bali
  module Reveal
    class Component < ApplicationViewComponent
      attr_reader :opened, :options

      renders_one :trigger, Reveal::Trigger::Component

      def initialize(opened: false, **options)
        @opened = opened
        @options = prepend_class_name(options,
                                      class_names('reveal-component', 'is-revealed': opened))
        @options = prepend_controller(@options, 'reveal')
      end
    end
  end
end
