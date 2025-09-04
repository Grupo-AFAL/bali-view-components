# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module Numeric
        class Component < ApplicationViewComponent
          attr_reader :form, :attribute, :title

          def initialize(form:, title:, attribute:, predicate:)
            @form = form
            @attribute = attribute
            @title = title
            @predicate = predicate

            @options = { id: input_id }
          end

          def input_id
            "#{form.model_name}_#{attribute}"
          end

          def input_name
            "#{form.model_name}[#{attribute}]"
          end
        end
      end
    end
  end
end
