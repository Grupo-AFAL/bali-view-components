# frozen_string_literal: true

module Bali
  module Form
    module Errors
      class Component < ApplicationViewComponent
        # @param model [ActiveModel::Model] The model object with errors
        # @param title [String, nil] Optional title displayed above the error list
        # @param class [String, nil] Additional CSS classes for the alert container
        def initialize(model:, title: nil, **options)
          @model = model
          @title = title
          @options = options
        end

        def render?
          @model.errors.any?
        end

        private

        attr_reader :model, :title

        def error_messages
          model.errors.full_messages
        end

        def component_options
          prepend_class_name(@options, 'mb-4')
        end
      end
    end
  end
end
