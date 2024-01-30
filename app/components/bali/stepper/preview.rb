# frozen_string_literal: true

module Bali
  module Stepper
    class Preview < ApplicationViewComponentPreview
      # Basic Stepper
      # -------------------
      # Stepper with 3 steps
      # @param current [Integer] select [0, 1, 2]
      def default(current: 0)
        render Bali::Stepper::Component.new(current: current) do |c|
          c.with_step(title: 'Paso 1')
          c.with_step(title: 'Paso 2')
          c.with_step(title: 'Paso 3')
        end
      end
    end
  end
end
