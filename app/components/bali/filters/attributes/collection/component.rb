# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module Collection
        class Component < Bali::Filters::Attributes::Base::Component
          attr_reader :form, :attribute, :collection_options, :title, :multiple

          # rubocop: disable Metrics/ParameterLists
          def initialize(
            form:, title:, attribute:, collection_options:, predicate:, multiple: true,
            **
          )
            super(form: form, title: title, attribute: attribute, predicate: predicate, **)

            @collection_options = collection_options
            @multiple = multiple

            @options = prepend_class_name(@options, 'column')
            @options = prepend_controller(@options, 'filter-attribute')
            @options = prepend_values(@options, 'filter-attribute', multiple: multiple)
          end
          # rubocop: enable Metrics/ParameterLists

          def selected_values
            Array(form.send(attribute)).map(&:to_s)
          end

          def input_name
            "#{form.model_name}[#{attribute}]#{'[]' if multiple}"
          end
        end
      end
    end
  end
end
