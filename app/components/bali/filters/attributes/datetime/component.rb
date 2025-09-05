# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module Datetime
        class Component < Bali::Filters::Attributes::Base::Component
          def value
            return (@form.send(@attribute) || []).compact_blank if multiple?
            return  @form.send(@attribute)&.strftime('%H:%M') if input_type == :time

            @form.send(@attribute)
          end

          def attribute_type
            @form.class._default_attributes[@attribute.to_s].type
          end

          def input_type
            case attribute_type
            when ActiveModel::Type::Time
              :time
            when ActiveModel::Type::Date
              :date
            else :datetime
            end
          end
        end
      end
    end
  end
end
