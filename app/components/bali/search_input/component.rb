# frozen_string_literal: true

module Bali
  module SearchInput
    class Component < ApplicationViewComponent
      attr_reader :form, :method, :placeholder, :auto_submit

      def initialize(form:, method:, auto_submit: false, **options)
        @form = form
        @method = method
        @auto_submit = auto_submit
        @placeholder = options.delete(:placeholder)
        @class = options.delete(:class)
      end

      def value
        form.send(method)
      end

      def input_id
        "#{form.model_name}_#{method}"
      end

      def input_name
        "#{form.model_name}[#{method}]"
      end

      def input_class
        class_names('input', @class)
      end

      def field_class
        class_names('field', 'has-addons': !auto_submit)
      end

      def control_class
        class_names('control', 'search-bar': auto_submit)
      end

      def input_data
        return {} unless auto_submit

        { action: 'submit-on-change#submit' }
      end
    end
  end
end
