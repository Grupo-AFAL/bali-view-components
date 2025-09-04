# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module Text
        class Component < Bali::Filters::Attributes::Base::Component
          def multiple?
            @attribute.to_s.ends_with?('_all') || @attribute.to_s.ends_with?('_any')
          end

          def input_name
            multiple? ? "#{super}[]" : super
          end
        end
      end
    end
  end
end
