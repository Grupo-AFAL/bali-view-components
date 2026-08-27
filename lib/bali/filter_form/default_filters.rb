# frozen_string_literal: true

module Bali
  class FilterForm
    # The `default:` declarations of a form, turned into the `q` params that apply them
    # (#1096).
    #
    # A listing can open on a question rather than on everything: the people catalog shows
    # the active roster, not the group's whole history. That default has exactly one place
    # it can live, and it is **the URL**.
    #
    # Not the scope, and not `ransack_params`: everything the DataTable builds afterwards
    # is built from `params`. `Bali::Table::Header::Component` delegates to Ransack's
    # `sort_link`, which composes the href out of what is in the URL, and so does the
    # pagination. A default injected underneath survives neither — the screen opens
    # filtered, the user sorts a column, and the population changes with nothing on screen
    # to explain it.
    #
    # And not the widget either, which is where `default:` used to stop: it preselected the
    # SimpleFilters control and never reached Ransack, so the select read "Active" over a
    # listing that showed everyone. Same disagreement, opposite side. Putting the value in
    # the URL is what makes the control, the query and the shareable link say one thing.
    #
    # {Bali::Filterable#redirect_to_default_filters} is the controller half — this side only
    # says what the defaults ARE.
    module DefaultFilters
      extend ActiveSupport::Concern

      class_methods do
        # The `q` params carrying every declared `default:`, each shaped the way the UI
        # that owns its attribute reads it back: flat under `q` for a `simple: true`
        # attribute, so its own control shows the value; as a condition of the advanced
        # panel's first group otherwise, so it renders as a pill the user can remove.
        #
        # @return [Hash{String => Object}] empty when the form declares no defaults
        def default_filter_params
          simple, advanced = filter_attributes.select { |attr| default_declared?(attr) }
                                              .partition { |attr| attr[:simple] }

          params = simple.reduce({}) { |acc, attr| acc.merge(simple_default_params(attr)) }
          conditions = advanced_default_conditions(advanced)
          return params if conditions.blank?

          # `m` explicitly: a group with no combinator parses as OR, and two defaults are
          # the one question a listing opens with — both of them, not either.
          params.merge("g" => { "0" => conditions.merge("m" => "and") })
        end

        private

        # `nil` and `""` are "no default". `false` is one — a boolean filter that opens
        # showing only the negatives is a real listing, and `present?` would eat it.
        def default_declared?(attr)
          value = attr[:default]
          !value.nil? && value != ""
        end

        # The key a simple filter travels under is the same one
        # {SimpleFiltersConfiguration#simple_filter_key} builds for its current value —
        # a date range has no single predicate, and a number range is a pair.
        def simple_default_params(attr)
          value = resolve_default(attr[:default])

          case attr[:input]
          when :number_range
            min, max = value.to_h.symbolize_keys.values_at(:min, :max)
            { "#{attr[:key]}_gteq" => min, "#{attr[:key]}_lteq" => max }.compact_blank
          when :date_range
            { attr[:key].to_s => value }
          else
            { "#{attr[:key]}_#{attr[:predicate]}" => value }
          end
        end

        def advanced_default_conditions(attrs)
          attrs.each_with_object({}) do |attr, conditions|
            conditions["#{attr[:key]}_#{attr[:predicate]}"] = resolve_default(attr[:default])
          end
        end

        # There is no instance to `instance_exec` against here — a default is asked for
        # before the form exists, by the controller deciding whether to redirect. So a
        # callable default runs plainly, without `scope`, which is the right limit anyway:
        # a default is the question the listing opens with, not something derived from
        # what it found.
        def resolve_default(value)
          value.respond_to?(:call) ? value.call : value
        end
      end
    end
  end
end
