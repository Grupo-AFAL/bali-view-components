# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module CheckBox
        class Component < Bali::Filters::Attributes::Base::Component
          def input_id
            input_name.gsub(/[\[\]]+/, '_').gsub(/-+/, '_')
          end
        end
      end
    end
  end
end
