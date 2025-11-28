# frozen_string_literal: true

module Bali
  module Concerns
    module GlobalIdAccessors
      extend ActiveSupport::Concern

      class_methods do
        def global_id_accessors_for(*attr_names)
          attr_names.each do |attr_name|
            define_method :"#{attr_name}_global_id" do
              send(attr_name).try(:to_global_id)
            end

            define_method :"#{attr_name}_global_id=" do |value|
              send(:"#{attr_name}=", GlobalID::Locator.locate(value))
            end
          end
        end
      end
    end
  end
end
