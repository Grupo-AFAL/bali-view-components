# frozen_string_literal: true

module Bali
  module Filters
    module Attribute
      class Component < ApplicationViewComponent
        attr_reader :form, :attribute, :title

        def initialize(form:, title:, attribute:, **options)
          @form = form
          @title = title
          @attribute = attribute
          @options = options
          @display = options.delete(:display)
        end

        def call
          component = case field_type.to_sym
                      when :collection
                        Bali::Filters::Attributes::Collection::Component
                      when :check_box
                        Bali::Filters::Attributes::CheckBox::Component
                      when :numeric
                        Bali::Filters::Attributes::Numeric::Component
                      else
                        Bali::Filters::Attributes::Text::Component

                      end

          render component.new(
            form: @form, title: @title, attribute: @attribute, predicate: ransack_predicate,
            **@options
          )
        end

        %i[collection check_box numeric text].each do |type|
          define_method "#{type}_field?" do
            field_type == type
          end
        end

        def display_block?
          return false if collection_field? || check_box_field?

          @display.blank? || @display.to_sym == :block
        end

        def display_flex?
          collection_field? || check_box_field? || @display&.to_sym == :flex
        end

        private

        def field_type
          @field_type ||=
            if predicates_for_collection.include?(ransack_predicate)
              :collection
            elsif predicates_for_check_box.include?(ransack_predicate)
              :check_box
            elsif predicates_for_number_field.include?(ransack_predicate)
              :numeric
            else
              :text
            end
        end

        def ransack_predicate
          @ransack_predicate ||=
            Ransack::Predicate.names.find { |predicate| @attribute.to_s.ends_with?("_#{predicate}") }
        end

        def predicates_for_number_field
          %w[lt lteq gt gteq]
        end

        def predicates_for_check_box
          %w[present blank null not_null true false]
        end

        def predicates_for_collection
          %w[in not_in not_eq_all]
        end
      end
    end
  end
end
