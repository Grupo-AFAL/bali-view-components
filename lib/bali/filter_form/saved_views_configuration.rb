# frozen_string_literal: true

module Bali
  class FilterForm
    # SavedViewsConfiguration — NAMED filter combinations (saved views).
    #
    # The FilterForm defines the WHAT of the storage, not the WHERE (same spirit as the
    # persistence through Rails.cache). `saved_views_store:` accepts any object with this
    # contract:
    #
    #   store.list                   -> [view, ...]     # views visible to the current user
    #   store.find(id)               -> view | nil
    #   store.save(name:, payload:)  -> view            # upsert by name
    #   store.delete(id)             -> void
    #
    # where each `view` answers `id`, `name` and `payload` (a Hash with the PAYLOAD_KEYS
    # keys). The FilterForm only READS (list/find): saving/renaming/deleting are done by the
    # controller that owns the URL the UI receives (Bali::DataTable::SavedViews).
    #
    # The engine SHIPS the default implementation of that contract:
    # `saved_views_store: :default` resolves to `Bali::SavedView::Store` (table
    # `bali_saved_views`, installed with `bin/rails bali:install:migrations`), scoped to the
    # `saved_views_owner:` the app passes (e.g. current_user) and to the form's `storage_id:`;
    # the mutations are served by `Bali::SavedViewsController` (routes of the mounted engine).
    # An app can still pass its own store — e.g. "views shared by team" is ANOTHER
    # implementation of the same contract (scoped to the team instead of the user), without
    # touching Bali.
    #
    # Application: `?saved_view=<id>` in the URL. The payload REPLACES the filter state (a
    # view is a complete state, not a merge) and then goes through the normal persistence of
    # `fetch_stored_filter_state`, so the applied view becomes the listing's "last state" when
    # navigating back.
    module SavedViewsConfiguration
      # Allowed keys of a view's payload. `columns` (the column selector's visible indexes) is
      # added by the dropdown's Stimulus when SAVING and consumed by the column selector when
      # APPLYING — the FilterForm only transports it.
      PAYLOAD_KEYS = %w[attributes simple_filters groupings combinator search_value group_by
                        columns].freeze

      def saved_views_enabled?
        @saved_views_store.present?
      end

      # Memoized: the dropdown asks for it more than once per render (.any? and then .each)
      # and every call without the memo was a SELECT.
      def saved_views
        @saved_views ||= saved_views_enabled? ? Array(@saved_views_store.list) : []
      end

      # The view applied by URL (?saved_view=<id>), or nil. Memoizes even the nil (a deleted
      # or someone else's id must not re-query the store on every call).
      def current_saved_view
        return @current_saved_view if defined?(@current_saved_view)

        @current_saved_view =
          (@saved_views_store.find(@saved_view_param) if saved_views_enabled? && @saved_view_param.present?)
      end

      # The view the current state COMES FROM, even when its filters have already been
      # changed. Unlike {#current_saved_view}, this applies nothing: it only remembers the
      # origin so that "Update 'X'" can be offered. A deleted view resolves to nil without
      # breaking.
      def saved_view_origin
        return @saved_view_origin if defined?(@saved_view_origin)

        @saved_view_origin =
          if saved_views_enabled? && @saved_view_origin_param.present?
            @saved_views_store.find(@saved_view_origin_param)
          end
      end

      # The raw id, so that forms and links can carry it along without touching the store.
      def saved_view_origin_id = @saved_view_origin_param

      # Has the current state DRIFTED from the view it comes from? It is the only condition
      # that justifies offering "Update": with no changes there is nothing to save.
      def saved_view_dirty?
        origin = saved_view_origin
        origin.present? && !view_matches_current_state?(origin)
      end

      # Visible column indexes the applied view carries saved (or nil): the DataTable passes
      # them to the column selector so that the initial state is the view's.
      def saved_view_columns
        current_saved_view && normalized_view_payload(current_saved_view)["columns"]
      end

      # Does the CURRENT form state (already post-persistence) equal this view's payload?
      # It compares normalized: String keys, without `columns` (it lives in the DOM) and
      # without empty values — so an applied view keeps being recognized as active even when
      # the URL no longer carries ?saved_view= (e.g. after navigating back with the state
      # restored from the cache).
      #
      # A payload that normalizes to EMPTY never matches by state: a "columns only" view (or
      # "see everything") describes the clean state, so it would match on every visit and be
      # marked active without its columns being applied —columns is only applied with
      # ?saved_view=—. Those views are only recognized as active when applied by URL.
      def view_matches_current_state?(view)
        state_matches_current_state?(normalized_view_payload(view))
      end

      # Same contract for a state that comes from a URL (the dropdown's static shortcuts): it
      # is given the payload's shape and compared the same way.
      def state_matches_current_state?(payload)
        comparable = comparable_view_state(payload)
        return false if comparable.empty?

        comparable == comparable_view_state(current_view_payload)
      end

      # The full CURRENT state, ready to be saved as a view. Without `columns`: that lives in
      # the DOM (column selector) and the dropdown's Stimulus adds it at submit time.
      def current_view_payload
        {
          "attributes" => attributes.reject { |_k, v| v.nil? || v == "" || v == [] },
          # The simple filters go apart and NOT inside `attributes`: their value is never an
          # ActiveModel attribute —it lives in `@q_params` and goes straight to Ransack—, so
          # `attributes` does not see them. Without this, a view saved from a simplified index
          # was born without its narrowing: `country_eq=USA` was measured cutting 25 rows down
          # to 5 and the payload came out as `{"attributes"=>{}, "search_value"=>"pic"}`.
          "simple_filters" => active_simple_filters.presence,
          "groupings" => @groupings,
          "combinator" => @combinator,
          "search_value" => @search_value,
          # To String, not the Symbol from `resolve_group_by`: this payload is compared against
          # one that ALREADY came back from a jsonb, where everything is a String.
          # `comparable_view_state` normalizes the KEYS but not the values, so `:genre` never
          # matched `"genre"` and a view that groups was not recognized as active by state —
          # only with `?saved_view=` in place.
          #
          # A default is not a choice, and writing it here made every saved view without
          # grouping read as "modified" against a listing nobody touched (#1156).
          "group_by" => group_by_preserved_value
        }.compact
      end

      private

      # `:default` = the engine's storage, scoped to the owner and to the form's storage_id.
      # With no owner or no storage_id there is no store (the dropdown does not paint): better
      # switched off than a badly built scope. An explicit store passes through intact.
      def resolve_saved_views_store(store, owner)
        return store unless store == :default
        return nil unless owner.present? && storage_id.present?

        Bali::SavedView.store_for(owner, storage_id)
      end

      # Canonical shape for comparing states: String keys all the way down, without `columns`
      # and without empty values (a payload saved with no combinator and a current state with
      # a nil combinator are the same state).
      #
      # NO-OP combinators are discarded too: the builder always re-emits `m` per group (and
      # `q[m]` at the top) even when the original state did not carry it, so without this a
      # shortcut or a view stopped being recognized as active after the first round-trip
      # through the popover or the search box. It is only discarded where the combinator
      # cannot change the result —a one-condition group, or a single group—, never when it
      # really tells AND from OR.
      def comparable_view_state(payload)
        state = payload.to_h.deep_stringify_keys.except("columns").reject { |_k, v| v.blank? }
        groupings = state["groupings"]
        if groupings.is_a?(Hash)
          state["groupings"] = groupings.transform_values do |group|
            group.is_a?(Hash) && group.except("m").size < 2 ? group.except("m") : group
          end
          state = state.except("combinator") if groupings.size < 2
        end
        state.reject { |_k, v| v.blank? }
      end

      # The payload comes either from a jsonb round-trip (String keys) or from a freshly built
      # Hash (Symbol keys): it is normalized to String and trimmed to the contract.
      def normalized_view_payload(view)
        payload = view.payload || {}
        payload = payload.to_h if payload.respond_to?(:to_h)
        payload.transform_keys(&:to_s).slice(*PAYLOAD_KEYS)
      end

      # Replaces the state derived from `q` with the applied view's. Returns the attributes
      # hash filtered by the declared ones (the same gate as the normal params path);
      # `group_by` goes through resolve_group_by's whitelist again — an old payload with a
      # withdrawn attribute simply loses it, without blowing up.
      def apply_saved_view_state
        payload = normalized_view_payload(current_saved_view)
        @groupings = payload["groupings"]
        # A view saved before combinator sanitization landed could still carry a poisoned
        # `m`; collapse it here too, so an old payload cannot re-emit it.
        @combinator = sanitized_combinator(payload["combinator"])
        @search_value = payload["search_value"]
        # Same contract as `attributes`: it REPLACES, it does not merge. An old payload, saved
        # before the key existed, arrives without it and clears the simple filters — which is
        # correct: that view describes a state that did not have them.
        apply_simple_filter_state(payload["simple_filters"])
        # An explicit `group_by` in the URL beats the payload's: with `?saved_view=` still
        # stuck on (the "Group by" links preserve the query), the payload overwrote the click
        # just made and the control looked dead.
        #
        # A view SPEAKS by carrying the key, not by carrying a value that resolves. A MISSING
        # key stays silence and not "no grouping": that is what every view saved before the
        # default existed carries, and there the default still speaks (#1156).
        @group_by = @group_by.presence || resolve_group_by(payload["group_by"])
        @group_by_chosen ||= payload.key?("group_by")
        (payload["attributes"] || {}).select { |k, _v| self.class.attribute_names.include?(k.to_s) }
      end
    end
  end
end
