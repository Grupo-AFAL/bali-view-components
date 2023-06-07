# frozen_string_literal: true

module Bali
  module Filters
    module Attribute
      class Component < ApplicationViewComponent
        attr_reader :form, :attribute, :collection_options, :title, :multiple

        def initialize(form:, attribute:, collection_options:, title:, multiple: true)
          @form = form
          @attribute = attribute
          @collection_options = collection_options
          @title = title
          @multiple = multiple

          @options = { id: input_id }
          @options = prepend_class_name(@options, 'column')
          @options = prepend_controller(@options, 'filter-attribute')
          @options = prepend_values(@options, 'filter-attribute', multiple: multiple)
        end

        def selected_values
          Array(form.send(attribute)).map(&:to_s)
        end

        def input_id
          "#{form.model_name}_#{attribute}"
        end

        def input_name
          "#{form.model_name}[#{attribute}]#{multiple ? '[]' : nil}"
        end
      end
    end
  end
end
