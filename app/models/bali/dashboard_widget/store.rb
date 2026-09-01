# frozen_string_literal: true

module Bali
  class DashboardWidget
    # One owner's dashboard arrangement in one context: which widgets, in what
    # order, at what size. The only thing that reads or writes
    # `bali_dashboard_widgets`.
    #
    # A host that already persists dashboards can pass its own object instead and
    # never run the migration. `Bali::Testing::StoreContract` is the contract —
    # an assertion a replacement includes and runs, rather than a paragraph here
    # that nothing checks and the next refactor silently invalidates.
    #
    # NOTE `context` here is the SCOPING STRING — a tenant id, or "" for a
    # single-tenant host. Unrelated to `Bali::Widget::Base#context`, which is the
    # actor a host's `authorized?` gates against. This class never sees that one.
    class Store
      # `offering` is REQUIRED and GATED HERE. An empty offer is a valid state but
      # a disastrous default — `arrange` would lose its delete half, `choose`
      # would no-op and `widgets` would render nothing, none of them raising.
      # Gating here rather than trusting callers means a host that passes its raw
      # catalogue cannot persist widgets whose `authorized?` is false.
      def initialize(owner:, dashboard_key:, offering:, context: "")
        # ON WHAT WAS OFFERED, not on what survived `authorized?`. A collision is
        # a property of the CODE — which is why it left `by_key`, where it ran on
        # every read, write and refresh poll — and checking the gated set would
        # make it a property of the REQUEST again: two colliding classes with one
        # role-gated would pass for every ordinary user and raise for the first
        # admin, mid-render, in production.
        #
        # Here rather than only in the `dashboard_widgets` macro because this
        # class is a documented standalone API, and a host skipping the concern
        # got no check at all — `arrange` wrote one row for the shared key and
        # `#widgets` served one widget's data under the other's rows.
        Bali::Widget.check_keys!(offering)

        @owner = owner
        @context = context.to_s
        @dashboard_key = dashboard_key.to_s
        @offering = Bali::Widget.authorized_for(offering)
      end

      # MEMOISED, because the picker asks `visible_keys` once per offered widget
      # while building its checkboxes — seventeen identical SELECTs on the dummy's
      # catalogue — and `customized?` asks again at the bottom of the same page.
      #
      # INVALIDATED BY THE WRITERS, which is the part a bare `||=` gets wrong:
      # the same `Store` is read before and after its own `arrange`, and `adopt`
      # does exactly that — it asks `visible_keys`, writes, and the caller then
      # reads the keys back. A stale memo answers with what was there before.
      def stored_keys = @stored_keys ||= rows.ordered.pluck(:widget_key)

      # `stored_keys` answers "has this owner ever chosen anything"; this answers
      # "is there anything on their dashboard". A surface that wants the second
      # and asks the first renders defaults while calling the owner customized.
      def visible_keys = stored_keys & offering.map(&:key)

      def customized? = visible_keys.any?

      # Returns `Placement`s — a widget AT A SIZE, since size belongs to the
      # arrangement rather than to the widget.
      #
      # Can only return members of the offering, so a key whose role was revoked,
      # whose flag is off, whose class was deleted, or that was hand-edited into
      # the table all collapse to the same `nil` from one lookup.
      def widgets
        by_key = indexed
        chosen = rows.ordered.pluck(:widget_key, :size).filter_map do |key, size|
          widget = by_key[key]
          Bali::Widget::Placement.new(widget: widget, size: size) if widget
        end

        # "No rows means never chose" is really "no VISIBLE rows means never
        # chose" — a dashboard holding only hidden ones would render empty
        # rather than falling back.
        chosen.presence || offering.map { |widget| Bali::Widget::Placement.new(widget: widget) }
      end

      # Membership, not order — what a picker submits. A picker renders in
      # catalog order, so writing position from that order would reshuffle a
      # dashboard the owner had arranged. Survivors keep their stored order;
      # newly chosen widgets append.
      #
      # A survivor also keeps its stored SIZE. `arrange` is a full reconcile, so
      # without carrying it forward here every `choose` would silently reset
      # every sized card back to its default.
      def choose(widgets)
        by_key = Bali::Widget.by_key(widgets)

        rows.transaction do
          stored = rows.ordered.pluck(:widget_key, :size).to_h
          survivors = stored.keys & by_key.keys

          arrange((survivors | by_key.keys).map { |key| { key: key, size: stored[key] } })
        end
      end

      # Reconcile to exactly `layout`, where POSITION IS THE INDEX and a missing
      # size means "no opinion". Takes either shape:
      #
      #   store.arrange(params.expect(widgets: [[ :key, :size ]]))
      #   store.arrange(store.widgets)   # `[Placement]`, so a read round-trips
      #
      # THE BOUNDARY. Every key is resolved against the offering, and one that is
      # not in it — unauthorized, retired, hand-edited into the payload — is
      # DROPPED. Silently: a role revoked between render and submit should
      # degrade rather than 422, and refusing a made-up key would confirm which
      # keys are real.
      #
      # An EMPTY layout is a reset, which is what an emptied grid means.
      def arrange(layout)
        @stored_keys = nil

        rows.transaction do
          # BEFORE the delete, the only chance to read them. This is a reconcile,
          # not an upsert, so without carrying `created_at` forward a widget that
          # has sat on the dashboard for a year is re-dated on every drag.
          born = rows.pluck(:widget_key, :created_at).to_h

          # ONLY THE ROWS THIS OFFERING COVERS. A widget behind a feature flag
          # that is off, or a role the owner just lost, is absent from the
          # offering — and `delete_all` would take its row with it, permanently:
          # the owner still has rows, so `#widgets` never falls back to defaults,
          # and the widget does not reappear when the flag comes back.
          #
          # This is the invariant `Bali::DashboardWidget` documents and the reason
          # `scope :ordered` tie-breaks on `widget_key`: a hidden row keeps its
          # ROW — its size and its `created_at` — while the visible ones renumber
          # around it, so positions collide and gaps are normal. The stored
          # `position` survives too but means little alone: where the widget
          # lands when it comes back depends on where the visible ones moved to.
          # The `_ordering` index is deliberately not unique. `arrange` used to
          # be the one writer that broke it.
          rows.where(widget_key: offering.map(&:key)).delete_all

          next if layout.empty?

          # Resolved before anything else, so the gate cannot be skipped by a
          # caller who already had `Placement`s. Deduped because `insert_all`
          # emits `ON CONFLICT DO NOTHING` and would otherwise keep only the
          # first occurrence of a repeated key, dropping the rest with no error.
          deduped = resolve(layout).uniq(&:key)

          next if deduped.empty?

          # One timestamp for the whole write; stamping inside `row_for` gave the
          # rows of a single logical write jittered `created_at`s.
          now = Time.current
          Bali::DashboardWidget.insert_all(
            deduped.map.with_index { |placement, index| row_for(placement, index, now, born) }
          )
        end
      end

      # "Make the defaults mine" — writes what an owner with no rows is already
      # being shown, so the arrangement stops being a fallback and becomes
      # something they can drag.
      #
      # IDEMPOTENT RATHER THAN LOCKED. Two concurrent adopts compute the same
      # defaults from the same offering and write the same rows, so the race has
      # one outcome whichever order it runs in.
      #
      # Two locks were tried here and both were wrong. Locking `rows` bought
      # nothing in the case this method exists for: `SELECT … FOR UPDATE` over an
      # empty scope locks nothing. Locking the OWNER row was worse — that is the
      # host's table, so an engine would be holding `FOR UPDATE` on host data in
      # a lock order the host cannot see or order against, and it still only
      # serialised `adopt` against `adopt` while `arrange`, `choose` and `reset`
      # took no lock at all.
      #
      # An `adopt` interleaved with an `arrange` is still last-write-wins. If that
      # ever needs defending, the primitive is an advisory lock keyed on
      # `[owner, dashboard_key]` taken by ALL FOUR writers — not one.
      def adopt
        rows.transaction do
          next if visible_keys.any?

          arrange(offering.map { |widget| { key: widget.key } })
        end
      end

      # No explicit transaction: one `DELETE` is already atomic.
      def reset
        @stored_keys = nil
        rows.delete_all
      end

      private

      attr_reader :owner, :context, :dashboard_key, :offering

      # THE OFFERING, INDEXED ONCE, and indexed DIRECTLY rather than through
      # `Bali::Widget.by_key`. `by_key` re-gates what it is handed so a caller
      # cannot widen the boundary by forgetting to filter — but this field was
      # gated in the constructor and is never written again, so the re-gate is a
      # second full pass of the host's `authorized?`, which may query.
      #
      # It added up: a refresh asked three times per widget (the controller's own
      # pass, this constructor's, and `#widgets`) and an arrange four. Two now,
      # and the remaining one belongs to the controller.
      def indexed = @indexed ||= offering.index_by(&:key)

      # A submission -> gated `[Placement]`. Never sees a list of permitted keys
      # to check against — it maps over the widgets themselves, so it cannot
      # conjure one whatever arrives.
      #
      # A `Placement` is re-resolved rather than passed through, so the guarantee
      # holds for `store.arrange(other_store.widgets)` too.
      def resolve(layout)
        by_key = indexed

        layout.filter_map do |item|
          key, size = fields_of(item)
          widget = by_key[key.to_s]
          Bali::Widget::Placement.new(widget: widget, size: size.presence) if widget
        end
      end

      # THROUGH `to_h`, doing two jobs beyond reading two fields.
      #
      # Key access becomes indifferent, so `{ "key" => … }` from parsed JSON
      # works. Reading `item[:key]` directly returns nil there, every row is
      # dropped, and `arrange` reads the empty result as a RESET — silent total
      # data loss.
      #
      # And an unpermitted `ActionController::Parameters` raises
      # `UnfilteredParameters` rather than quietly working.
      def fields_of(item)
        return [ item.key, item.size ] if item.is_a?(Bali::Widget::Placement)

        item.to_h.with_indifferent_access.values_at(:key, :size)
      end

      def rows
        Bali::DashboardWidget.where(owner: owner, context: context,
                                    dashboard_key: dashboard_key)
      end

      def row_for(placement, index, now, born)
        key = placement.key

        {
          owner_type: owner.class.polymorphic_name, owner_id: owner.id,
          context: context, dashboard_key: dashboard_key,
          widget_key: key, position: index,
          size: placement.size.to_s,
          # A widget already on the dashboard keeps the moment it arrived; one
          # removed and re-added is genuinely new, since absence of a row means
          # "off". `updated_at` is always now, which is the true claim.
          created_at: born.fetch(key, now), updated_at: now
        }
      end
    end
  end
end
