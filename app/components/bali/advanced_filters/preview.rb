# frozen_string_literal: true

module Bali
  module AdvancedFilters
    class Preview < Lookbook::Preview
      # @label Default
      # @param popover toggle "Show in popover vs inline"
      # @param apply_mode select { choices: [batch, live] } "Batch applies on submit, live applies immediately"
      # @param combinator select { choices: [and, or] } "How filter groups are combined"
      # @param max_groups number "Maximum number of filter groups"
      # Basic advanced filters with common attribute types.
      # Supports text, number, date, boolean, and select fields.
      def default(popover: true, apply_mode: :batch, combinator: :and, max_groups: 10)
        render AdvancedFilters::Component.new(
          url: '/preview',
          available_attributes: sample_attributes,
          popover: popover,
          apply_mode: apply_mode.to_sym,
          combinator: combinator.to_sym,
          max_groups: max_groups.to_i
        )
      end

      # @label With Initial Filters
      # @param combinator select { choices: [and, or] }
      # Shows the component with pre-populated filter groups.
      # Useful for demonstrating the UI with active filters.
      def with_initial_filters(combinator: :and)
        filter_groups = [
          {
            combinator: 'or',
            conditions: [
              { attribute: 'status', operator: 'eq', value: 'active' },
              { attribute: 'status', operator: 'eq', value: 'pending' }
            ]
          },
          {
            combinator: 'and',
            conditions: [
              { attribute: 'created_at', operator: 'gteq', value: '2026-01-01' }
            ]
          }
        ]

        render AdvancedFilters::Component.new(
          url: '/preview',
          available_attributes: sample_attributes,
          filter_groups: filter_groups,
          combinator: combinator.to_sym
        )
      end

      # @label With Applied Tags
      # Shows applied filter tags above the filter builder.
      # Tags allow users to see and remove individual filters quickly.
      def with_applied_tags
        filter_groups = [
          {
            combinator: 'or',
            conditions: [
              { attribute: 'status', operator: 'eq', value: 'active' },
              { attribute: 'name', operator: 'cont', value: 'John' }
            ]
          }
        ]

        render_with_template(
          template: 'bali/advanced_filters/previews/with_applied_tags',
          locals: {
            url: '/preview',
            available_attributes: sample_attributes,
            filter_groups: filter_groups
          }
        )
      end

      # @label All Field Types
      # @param popover toggle
      # Demonstrates all available field types: text, number, date, datetime, boolean, and select.
      # Each type has appropriate operators and input controls.
      def all_field_types(popover: true)
        attributes = [
          { key: :name, label: 'Name', type: :text },
          { key: :email, label: 'Email Address', type: :text },
          { key: :age, label: 'Age', type: :number },
          { key: :salary, label: 'Salary', type: :number },
          { key: :birth_date, label: 'Birth Date', type: :date },
          { key: :last_login, label: 'Last Login', type: :datetime },
          { key: :is_active, label: 'Active', type: :boolean },
          { key: :is_verified, label: 'Verified', type: :boolean },
          {
            key: :status,
            label: 'Status',
            type: :select,
            options: [
              ['Active', 'active'],
              ['Pending', 'pending'],
              ['Inactive', 'inactive'],
              ['Suspended', 'suspended']
            ]
          },
          {
            key: :role,
            label: 'Role',
            type: :select,
            options: [
              ['Admin', 'admin'],
              ['Manager', 'manager'],
              ['User', 'user'],
              ['Guest', 'guest']
            ]
          },
          {
            key: :department,
            label: 'Department',
            type: :select,
            options: [
              ['Engineering', 'engineering'],
              ['Marketing', 'marketing'],
              ['Sales', 'sales'],
              ['Support', 'support'],
              ['HR', 'hr']
            ]
          }
        ]

        render AdvancedFilters::Component.new(
          url: '/preview',
          available_attributes: attributes,
          popover: popover
        )
      end

      # @label Compact (Few Attributes)
      # Minimal configuration with only a few attributes.
      # Useful for simple filtering scenarios.
      def compact
        attributes = [
          { key: :name, label: 'Name', type: :text },
          {
            key: :status,
            label: 'Status',
            type: :select,
            options: [['Active', 'active'], ['Inactive', 'inactive']]
          }
        ]

        render AdvancedFilters::Component.new(
          url: '/preview',
          available_attributes: attributes
        )
      end

      private

      def sample_attributes
        [
          { key: :name, label: 'Name', type: :text },
          { key: :email, label: 'Email', type: :text },
          { key: :age, label: 'Age', type: :number },
          { key: :created_at, label: 'Created Date', type: :date },
          { key: :verified, label: 'Verified', type: :boolean },
          {
            key: :status,
            label: 'Status',
            type: :select,
            options: [
              ['Active', 'active'],
              ['Pending', 'pending'],
              ['Inactive', 'inactive']
            ]
          },
          {
            key: :role,
            label: 'Role',
            type: :select,
            options: [
              ['Admin', 'admin'],
              ['Manager', 'manager'],
              ['User', 'user']
            ]
          }
        ]
      end
    end
  end
end
