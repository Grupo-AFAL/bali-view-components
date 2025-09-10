# frozen_string_literal: true

module Bali
  module Filters
    module Attribute
      class Component < ApplicationViewComponent
        attr_reader :form, :attribute, :title

        delegate :collection_options, :multiple, to: :field_component

        def initialize(form:, title:, attribute:, **options)
          @form = form
          @title = title
          @attribute = attribute
          @options = options
          @display = options.delete(:display)
        end

        def call
          render field_component
        end

        %i[collection check_box date_range datetime text].each do |type|
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

        def field_component
          return @field_component if defined? @field_component

          component = case field_type.to_sym
                      when :collection
                        Bali::Filters::Attributes::Collection::Component
                      when :check_box
                        Bali::Filters::Attributes::CheckBox::Component
                      when :date_range
                        Bali::Filters::Attributes::DateRange::Component
                      when :datetime
                        Bali::Filters::Attributes::Datetime::Component
                      else
                        Bali::Filters::Attributes::Text::Component
                      end

          @field_component = component.new(
            form: @form, title: @title, attribute: @attribute, **@options
          )
        end

        def field_type
          @field_type ||=
            if @options[:collection_options].present? || collection_predicate?
              :collection
            elsif date_range_types.include?(attribute_type)
              :date_range
            elsif check_box_types.include?(attribute_type)
              :check_box
            elsif datetime_types.include?(attribute_type)
              :datetime
            else
              :text
            end
        end

        def attribute_type
          @form.class._default_attributes[@attribute.to_s].type.class
        end

        def date_range_types
          [Bali::Types::DateRangeValue]
        end

        def text_and_numeric_types
          [
            ActiveModel::Type::String, ActiveModel::Type::ImmutableString,
            ActiveModel::Type::Integer, ActiveModel::Type::BigInteger,
            ActiveModel::Type::Decimal, ActiveModel::Type::Float
          ]
        end

        def check_box_types
          [ActiveModel::Type::Boolean]
        end

        def datetime_types
          [ActiveModel::Type::Date, ActiveModel::Type::DateTime, ActiveModel::Type::Time]
        end

        def collection_predicate?
          %w[_in _not_in].any? { |predicate| @attribute.ends_with?(predicate) }
        end
      end
    end
  end
end
