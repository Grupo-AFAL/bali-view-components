# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module Collection
        class Component < Bali::Filters::Attributes::Base::Component
          attr_reader :form, :attribute, :collection_options, :title, :multiple

          def initialize(
            form:, title:, attribute:, collection_options:, multiple: true,
            **
          )
            super(form: form, title: title, attribute: attribute, **)

            @collection_options = collection_options
            @multiple = multiple

            @options = prepend_class_name(@options, 'column') if collection_options.size <= 5
            @options = prepend_controller(@options, 'filter-attribute')
            @options = prepend_values(@options, 'filter-attribute', multiple: multiple)
          end

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
