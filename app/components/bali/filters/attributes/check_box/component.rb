# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module CheckBox
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
            input_name.gsub(/[\[\]]+/, '_').gsub(/-+/, '_')
          end

          def input_name
            "#{form.model_name}[#{attribute}]"
          end
        end
      end
    end
  end
end
