# frozen_string_literal: true

module Bali
  module AdvancedFilters
    module AppliedTags
      class Component < ApplicationViewComponent
        include Utils::Url

        attr_reader :filter_groups, :available_attributes, :url

        def initialize(filter_groups:, available_attributes:, url:, **options)
          @filter_groups = filter_groups || []
          @available_attributes = available_attributes
          @url = url
          @options = options
        end

        def applied_filters
          @applied_filters ||= extract_applied_filters
        end

        def any_filters?
          applied_filters.any?
        end

        def clear_all_url
          add_query_param(url, :clear_filters, true)
        end

        private

        def extract_applied_filters
          filters = []

          filter_groups.each_with_index do |group, group_idx|
            (group[:conditions] || []).each_with_index do |condition, condition_idx|
              next if condition[:attribute].blank? || condition[:value].blank?

              attr_config = available_attributes.find { |a| a[:key].to_s == condition[:attribute].to_s }
              next unless attr_config

              filters << {
                group_index: group_idx,
                condition_index: condition_idx,
                attribute: condition[:attribute],
                attribute_label: attr_config[:label],
                operator: condition[:operator],
                operator_label: operator_label(condition[:operator], attr_config[:type]),
                value: condition[:value],
                value_label: value_label(condition[:value], attr_config)
              }
            end
          end

          filters
        end

        def operator_label(operator, type)
          operators = Bali::AdvancedFilters::Component.new(
            url: '',
            available_attributes: []
          ).operators_for_type(type)

          operators.find { |o| o[:value] == operator }&.dig(:label) || operator
        end

        def value_label(value, attr_config)
          return value unless attr_config[:type].to_sym == :select

          option = attr_config[:options].find do |opt|
            opt_value = opt.is_a?(Array) ? opt[1] : opt
            opt_value.to_s == value.to_s
          end

          if option.is_a?(Array)
            option[0]
          else
            option || value
          end
        end
      end
    end
  end
end
