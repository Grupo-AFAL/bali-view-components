# frozen_string_literal: true

module Bali
  class FilterForm
    # FilterGroupParser handles parsing of Ransack grouping params (q[g][...])
    # into structured filter groups for the Filters component.
    #
    # Ransack groupings support complex AND/OR conditions:
    #   q[g][0][name_cont]=john&q[g][0][status_eq]=active&q[g][0][m]=or
    #
    # This module parses these into a component-friendly structure:
    #   [{ combinator: 'or', conditions: [{attribute: 'name', ...}, ...] }]
    #
    module FilterGroupParser
      extend ActiveSupport::Concern

      # Ransack operators ordered by specificity (longer operators first to avoid partial matches)
      RANSACK_OPERATORS = %w[not_cont not_eq not_in gteq lteq cont start end matches eq gt lt
                             in].freeze

      # Parse the current filter state into a structure for Filters component.
      # Automatically extracts filter groups from Ransack grouping params (q[g][...]).
      #
      # @return [Array<Hash>] Array of filter groups, each with :combinator and :conditions
      # @example Return structure
      #   [
      #     {
      #       combinator: 'or',
      #       conditions: [
      #         { attribute: 'name', operator: 'cont', value: 'john' },
      #         { attribute: 'status', operator: 'eq', value: 'active' }
      #       ]
      #     }
      #   ]
      def filter_groups
        return [] if @groupings.blank?

        @groupings.map do |_index, group_params|
          parse_filter_group(group_params.deep_symbolize_keys)
        end
      end

      # Get the top-level combinator that determines how filter groups are combined.
      #
      # @return [String] 'and' or 'or'
      def combinator
        @combinator || 'and'
      end

      # Get detailed information about each active filter condition.
      # Useful for displaying filter pills/tags with human-readable labels.
      #
      # @return [Array<Hash>] Array of filter details with metadata
      def active_filter_details
        details = []
        filter_groups.each_with_index do |group, group_idx|
          group[:conditions].each_with_index do |condition, condition_idx|
            next if condition[:value].blank?

            attr_config = available_attributes.find do |a|
              a[:key].to_s == condition[:attribute].to_s
            end

            details << {
              group_index: group_idx,
              condition_index: condition_idx,
              attribute: condition[:attribute],
              attribute_label: attr_config&.dig(:label) || condition[:attribute].to_s.humanize,
              operator: condition[:operator],
              value: condition[:value],
              value_label: format_filter_value(condition[:value], attr_config)
            }
          end
        end
        details
      end

      private

      # Parse a single filter group from Ransack params into component structure.
      # Consolidates gteq/lteq pairs into 'between' operator for better UX.
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def parse_filter_group(group_params)
        raw_conditions = {}

        group_params.each do |key, value|
          next if key == :m # Skip combinator

          attr, operator = parse_condition_key(key.to_s)
          next unless attr

          raw_conditions[attr] ||= {}
          raw_conditions[attr][operator] = value
        end

        # Convert raw conditions, consolidating gteq+lteq into 'between'
        conditions = raw_conditions.flat_map do |attribute, ops|
          if ops['gteq'] && ops['lteq']
            # Combine into a single 'between' condition for date ranges
            [{
              attribute: attribute,
              operator: 'between',
              value: { start: ops['gteq'], end: ops['lteq'] }
            }]
          else
            ops.map do |operator, value|
              { attribute: attribute, operator: operator, value: value }
            end
          end
        end

        {
          combinator: group_params[:m] || 'or',
          conditions: conditions.presence || [default_filter_condition]
        }
      end
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # Parse a Ransack condition key like "name_cont" or "created_at_gteq"
      # into [attribute, operator] pair.
      def parse_condition_key(key)
        RANSACK_OPERATORS.each do |op|
          if key.end_with?("_#{op}")
            attr = key.sub(/_#{op}$/, '')
            return [attr, op]
          end
        end

        nil
      end

      # Default empty condition for new filter groups
      def default_filter_condition
        { attribute: '', operator: 'cont', value: '' }
      end

      # Format a filter value for display, resolving select option labels
      # rubocop:disable Metrics/CyclomaticComplexity
      def format_filter_value(value, attr_config)
        return value if attr_config.nil?
        return value unless attr_config[:type]&.to_sym == :select

        option = attr_config[:options]&.find do |opt|
          opt_value = opt.is_a?(Array) ? opt[1] : opt
          opt_value.to_s == value.to_s
        end

        option.is_a?(Array) ? option[0] : (option || value)
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
