# frozen_string_literal: true

module Bali
  module AdvancedFilters
    class Preview < Lookbook::Preview
      # @label Default
      # Basic advanced filters with common attribute types
      def default
        render Component.new(
          url: '/users',
          available_attributes: sample_attributes
        )
      end

      # @label With Initial Filters
      # Shows the component with pre-populated filter groups
      def with_initial_filters
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

        render Component.new(
          url: '/users',
          available_attributes: sample_attributes,
          filter_groups: filter_groups,
          combinator: :and
        )
      end

      # @label With Applied Tags
      # Shows applied filter tags above the filter builder
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
            url: '/users',
            available_attributes: sample_attributes,
            filter_groups: filter_groups
          }
        )
      end

      # @label Multiple Groups
      # Complex filtering with multiple groups and conditions
      def multiple_groups
        filter_groups = [
          {
            combinator: 'or',
            conditions: [
              { attribute: 'role', operator: 'eq', value: 'admin' },
              { attribute: 'role', operator: 'eq', value: 'manager' }
            ]
          },
          {
            combinator: 'and',
            conditions: [
              { attribute: 'status', operator: 'eq', value: 'active' },
              { attribute: 'verified', operator: 'eq', value: 'true' }
            ]
          },
          {
            combinator: 'or',
            conditions: [
              { attribute: 'created_at', operator: 'gteq', value: '2025-01-01' },
              { attribute: 'created_at', operator: 'lteq', value: '2025-12-31' }
            ]
          }
        ]

        render Component.new(
          url: '/users',
          available_attributes: sample_attributes,
          filter_groups: filter_groups,
          combinator: :and
        )
      end

      # @label All Field Types
      # Demonstrates all available field types
      def all_field_types
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

        render Component.new(
          url: '/users',
          available_attributes: attributes
        )
      end

      # @label Compact (Few Attributes)
      # Minimal configuration with only a few attributes
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

        render Component.new(
          url: '/items',
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
