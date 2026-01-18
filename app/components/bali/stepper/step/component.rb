# frozen_string_literal: true

module Bali
  module Stepper
    module Step
      class Component < ApplicationViewComponent
        # DaisyUI step color classes (applied to completed/active steps)
        COLORS = {
          primary: 'step-primary',
          secondary: 'step-secondary',
          accent: 'step-accent',
          neutral: 'step-neutral',
          info: 'step-info',
          success: 'step-success',
          warning: 'step-warning',
          error: 'step-error'
        }.freeze

        # Unicode checkmark for completed steps
        CHECKMARK = "\u2713"

        attr_reader :title

        def initialize(title:, current:, index:, color: :primary, **options)
          @title = title
          @current = current
          @index = index
          @color = color
          @options = options
        end

        def status
          return :active if index == current
          return :done if index < current

          :pending
        end

        def done?
          status == :done
        end

        def active?
          status == :active
        end

        def pending?
          status == :pending
        end

        private

        attr_reader :current, :index, :color, :options

        def step_classes
          class_names(
            'step',
            completed_color_class,
            options[:class]
          )
        end

        # Only completed (done/active) steps get the color class in DaisyUI
        def completed_color_class
          COLORS.fetch(color, COLORS[:primary]) if done? || active?
        end

        def step_options
          options.except(:class).merge(
            class: step_classes,
            data: step_data
          )
        end

        def step_data
          base_data = options[:data] || {}
          done? ? base_data.merge(content: CHECKMARK) : base_data
        end
      end
    end
  end
end
