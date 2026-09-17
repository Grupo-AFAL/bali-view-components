# frozen_string_literal: true

module Bali
  module Filters
    module FilterGroup
      class Component < ApplicationViewComponent
        # What a group nobody has touched yet combines its conditions with. The one
        # place it is written: the parser (`FilterGroupParser`) reads it for a group
        # that arrives without `m`, `Filters::Component` and the group template seed
        # new groups with it, and `filter_group_controller.js` repeats it as the
        # Stimulus default for the case where the data attribute is missing.
        #
        # AND, because adding a condition to a group is what a user means by "add a
        # filter", and a second condition has to narrow the listing, not widen it — it
        # was OR, and «marca = WCP» (5 rows) plus «distrito = I» came back with 23
        # (#1121). It is also what Ransack applies to a group with no `m`
        # (`Nodes::Grouping` with a nil combinator), so the panel now says what the
        # query does. A group that chose OR keeps it: this is only the seed.
        DEFAULT_COMBINATOR = "and"

        attr_reader :group, :index, :available_attributes, :removable

        # @param group [Hash] The filter group data
        #   { combinator: 'or', conditions: [{ attribute:, operator:, value: }] }
        # @param index [Integer, String] The group index for form field naming
        # @param available_attributes [Array<Hash>] Available filterable attributes
        # @param removable [Boolean] Whether this group can be removed
        def initialize(group:, index:, available_attributes:, removable: false)
          @group = group || default_group
          @index = index
          @available_attributes = available_attributes
          @removable = removable
        end

        def combinator
          @group[:combinator] || DEFAULT_COMBINATOR
        end

        def conditions
          @group[:conditions] || [ default_condition ]
        end

        def group_field_prefix
          "q[g][#{index}]"
        end

        def and_button_classes
          class_names(
            "join-item btn btn-xs w-10",
            combinator == "and" ? "btn-primary" : "btn-outline"
          )
        end

        def or_button_classes
          class_names(
            "join-item btn btn-xs w-10",
            combinator == "or" ? "btn-primary" : "btn-outline"
          )
        end

        private

        def default_group
          {
            combinator: DEFAULT_COMBINATOR,
            conditions: [ default_condition ]
          }
        end

        def default_condition
          {
            attribute: "",
            operator: "cont",
            value: ""
          }
        end
      end
    end
  end
end
