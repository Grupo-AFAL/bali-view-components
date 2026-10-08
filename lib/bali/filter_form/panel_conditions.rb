# frozen_string_literal: true

module Bali
  class FilterForm
    # Only what the advanced panel can write reaches Ransack (#1346). `q[g]` also arrives from
    # a hand-written URL, a saved view or the filter cache, and with the last two a condition
    # that breaks the query is a 500 on every visit: a NUL byte (Postgres: `string contains
    # null byte`), an id past its column inside an `_in` (`ActiveModel::RangeError` on either
    # engine), a text operator on a ransacker that answers only a select's four (identity's
    # `AppPermission::HeldRoles`). A nested `g` or Ransack's `c` filtered while the panel
    # painted an empty row. None of them is a filter now.
    module PanelConditions
      extend ActiveSupport::Concern

      # Postgres refuses a NUL in a string. The rest go too: a form post rewrites a line break
      # (LF to CRLF), so "select all N" re-emitting one would act on another set than the
      # listing showed.
      CONTROL_CHARACTER = /[[:cntrl:]]/

      private

      # The panel's groups as they are applied: `@groupings`, from whatever source, with
      # only the conditions the panel can write and values the query can take.
      #
      # Lazy, never in `initialize`: a host's `available_attributes` can read state its own
      # `initialize` sets after `super` (afal-apps' TDFlow::ProjectsFilterForm reads
      # `@population` there, and calls `groupings` before setting it). That is also why
      # `groupings` is normalized but not gated.
      #
      # Memoized per `@groupings` object: identity's AccountsFilterForm reads `filter_groups`
      # in its `initialize` and then reassigns `@groupings` with what "select all N" would
      # re-emit, and a plain memo kept applying the groups it had replaced.
      def applied_groupings
        unless defined?(@applied_groupings) && @applied_groupings_source.equal?(@groupings)
          @applied_groupings_source = @groupings
          @applied_groupings = normalize_groupings(@groupings)&.filter_map { |index, group|
            applicable = applicable_group(group.stringify_keys)
            [ index.to_s, applicable ] if applicable
          }.to_h.presence
        end
        @applied_groupings
      end

      # Ransack's two shapes for `g` — an indexed hash, or an array (`q[g][]`, which Bali does
      # not emit) — in the indexed one the rest of Bali speaks, keeping only the groups that
      # are hashes. A scalar group (`q[g][0]=x`) travelled whole to Ransack to blow up there,
      # and the array shape dodged the enum translation and returned the opposite records.
      def normalize_groupings(groupings)
        groups = unwrap_params(groupings)
        groups = groups.each_with_index.to_h { |group, index| [ index.to_s, group ] } if groups.is_a?(Array)
        return unless groups.is_a?(Hash)

        groups.transform_values { |group| unwrap_params(group) }.select { |_index, group| group.is_a?(Hash) }.presence
      end

      # The group's conditions that pass, with its combinator; nil when none does.
      def applicable_group(group)
        conditions = group.except("m").select { |key, value| applicable_condition?(key, value) }
        conditions.merge("m" => sanitized_combinator(group["m"])).compact if conditions.any?
      end

      def applicable_condition?(key, value)
        return false if panel_condition_keys && !panel_condition_keys.include?(key)

        queryable_condition?(key, value)
      end

      # The value the query can take under `key`, whoever wrote it: the panel, a flat
      # `attribute` or a simple filter (#1351).
      def queryable_condition?(key, value)
        return queryable_value?(value) unless list_predicate?(key)

        Array.wrap(value).all? { |member| queryable_value?(member) } && fits_column?(key, value)
      end

      # Every key the panel can write: each attribute of `available_attributes` with each
      # operator its type offers. "Between" travels as its `_gteq`/`_lteq` pair, which a date
      # already offers.
      #
      # nil when the form offers the panel no attribute (none declared, or all `advanced:
      # false`), and then any key goes and Ransack decides, as before: a bare
      # `FilterForm.new(scope, params)` whose panel takes its attributes in the view
      # (`with_filters_panel(available_attributes:)`, the DataTable previews), or
      # gobierno-corporativo's BusinessProcessesFilterForm, which reads `active_eq` from
      # `q[g]` with every attribute `advanced: false`.
      def panel_condition_keys
        return @panel_condition_keys if defined?(@panel_condition_keys)

        @panel_condition_keys = available_attributes.flat_map { |attribute|
          Bali::Filters::Operators.for_type(attribute[:type] || :text)
                                  .filter_map { |operator| "#{attribute[:key]}_#{operator[:value]}" unless operator[:range] }
        }.to_set.presence
      end

      # A list only where the operator takes one — of the panel's, `_in` and `_not_in`.
      # Elsewhere Ransack compares the column with the list's JSON (`genre = '["Drama"]'`), or
      # drops it while the panel paints it.
      def list_predicate?(key)
        predicate = Ransack::Predicate.detect_from_string(key)
        predicate.present? && Ransack::Predicate.named(predicate).wants_array
      end

      def queryable_value?(value)
        case value
        when String then !value.match?(CONTROL_CHARACTER)
        when Hash, Array, ActionController::Parameters then false
        else true
        end
      end

      # A list is serialized member by member with the type of the column the condition
      # reaches, and a member past it raises `ActiveModel::RangeError` while the query is
      # built: an `integer` stops at 2**31 in Postgres and at 2**63 in SQLite. A single value
      # is inlined (`_eq`, `_gt`) and answers no rows, which is right, so only lists are
      # asked. A ransacker has no column to ask.
      def fits_column?(key, value)
        return true if value.blank?

        condition = ransack_condition(key, value)
        return true if condition.nil?

        condition.attributes.all? do |attribute|
          next true if attribute.ransacker

          type = attribute.klass.type_for_attribute(attribute.attr_name)
          Array.wrap(value).all? { |member| type.serializable?(member) }
        end
      end
    end
  end
end
