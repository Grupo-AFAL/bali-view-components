# frozen_string_literal: true

module Bali
  module Stepper
    module Step
      class Component < ApplicationViewComponent
        attr_reader :title, :current, :index, :options

        def initialize(title:, current:, index:, **options)
          @title = title
          @current = current
          @index = index
          @options = prepend_class_name(options, "step-component is-#{status}")
        end

        def status
          return :active if index == current
          return :done if index < current

          :pending
        end

        def done?
          status == :done
        end
      end
    end
  end
end
