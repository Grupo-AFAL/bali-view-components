# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module Base
        class Component < ApplicationViewComponent
          attr_reader :form, :attribute, :title

          def initialize(form:, title:, attribute:, **options)
            @form = form
            @attribute = attribute
            @title = title

            @options = options.merge(id: input_id)
          end

          def input_id
            "#{form.model_name}_#{attribute}"
          end

          def input_name
            name = "#{form.model_name}[#{attribute}]"
            name += '[]' if multiple?
            name
          end

          def multiple?
            @attribute.to_s.ends_with?('_all') || @attribute.to_s.ends_with?('_any')
          end

          def predicate
            @predicate ||=
              Ransack::Predicate.names.find { |r_predicate| @attribute.to_s.ends_with?("_#{r_predicate}") }
          end
        end
      end
    end
  end
end
