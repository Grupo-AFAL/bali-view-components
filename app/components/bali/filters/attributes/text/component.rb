# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module Text
        class Component < Bali::Filters::Attributes::Base::Component
          def value
            @value ||= if multiple?
                         (@form.send(@attribute) || []).compact_blank
                       else
                         @form.send(@attribute)
                       end
          end

          def numeric_predicates
            %w[lt lteq gt gteq]
          end

          def numeric_field?
            numeric_predicates.include?(predicate)
          end
        end
      end
    end
  end
end
