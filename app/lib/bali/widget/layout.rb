# frozen_string_literal: true

module Bali
  module Widget
    # One owner's dashboard arrangement in one context: which widgets, in what
    # order, at what size. The only thing that reads or writes
    # `bali_dashboard_widgets`.
    #
    # NOTE `arrange` is `delete_all` + `insert_all`, so a row does not survive a
    # rearrange — a widget that has sat on the dashboard for a year gets a fresh
    # `created_at` every time anything is dragged. Nothing reads those timestamps
    # today, but it means "when did you first add this widget?" is permanently
    # unanswerable from this table, which is worth knowing before building on it.
    #
    # NOT an ActiveRecord model, deliberately. A `dashboards` table would hold an
    # owner, a context and two timestamps — pure join identity, bought with a
    # migration and an extra read on every request, to buy a name we can have for
    # free. Promote it the day a dashboard has state of its own.
    #
    # NOTE `context` here is the SCOPING STRING — a tenant id, or "" for a
    # single-tenant host. It is unrelated to `Bali::Widget::Base#context`, which
    # is the actor object a host's `visible?` gates against. This class never
    # sees that one.
    class Layout
      # The set the owner is being shown right now — already gated by the host.
      # State rather than an argument to three methods, because every one of them
      # needs it and all mean the same thing by it.
      #
      # REQUIRED, with no default, and that is deliberate. An empty offer is a
      # valid state (an owner authorized for nothing) but a terrible default:
      # `arrange` would lose its delete half, since `[] - submitted` is `[]`;
      # `choose` would become a no-op; and `widgets` would render nothing. Three
      # wrong behaviours from one forgotten argument, none of them raising.
      def initialize(owner:, dashboard_key:, offering:, context: "")
        @owner = owner
        @context = context.to_s
        @dashboard_key = dashboard_key.to_s
        @offering = offering
      end

      # EVERY stored key, including rows for widgets the owner cannot currently
      # see. Surfaces almost always want `visible_keys` instead.
      def stored_keys = rows.ordered.pluck(:widget_key)

      # The stored keys the owner can actually see, in stored order.
      #
      # Asking `stored_keys` means "has this owner ever chosen anything"; asking
      # this means "is there anything on their dashboard". A surface that wants
      # the second and asks the first renders defaults while reporting the owner
      # as customized.
      def visible_keys = stored_keys & offering.map(&:key)

      # VISIBLE keys, not rows. An owner whose only stored row is for a hidden
      # widget has customized nothing they can see, and telling them otherwise
      # offers "restore defaults" to someone already looking at defaults.
      def customized? = visible_keys.any?

      # THE INVARIANT.
      #
      # `offering` is ALWAYS the already-authorized set. This indexes what it
      # holds and can only return members of that set; it cannot conjure a
      # widget. Four failure modes collapse into the same `nil` from one lookup:
      #
      #   - a key for a widget whose role the owner lost -> not in `by_key`
      #   - a key for a widget whose feature flag is off -> not in `by_key`
      #   - a key for a widget deleted from the catalog  -> not in `by_key`
      #   - a key hand-edited into the table              -> not in `by_key`
      #
      # Safe by CONSTRUCTION rather than by filtering: the method never sees a
      # list of permitted keys to check against, it sees the widgets themselves
      # and maps over them. That is the difference between a boundary and a habit.
      def widgets
        by_key = offering.index_by(&:key)
        chosen = rows.ordered.pluck(:widget_key, :size).filter_map do |key, size|
          # `with_size` returns the widget at its own size for a nil or retired
          # one, so a row predating the size column still renders.
          by_key[key]&.with_size(size)
        end

        # "No rows means never chose" is really "no VISIBLE rows means never
        # chose": a dashboard holding only hidden ones would otherwise render
        # empty rather than falling back.
        chosen.presence || offering
      end

      # Membership, not order — what a picker submits.
      #
      # A picker renders in stable catalog order, so writing position from THAT
      # order would reshuffle a dashboard the owner had arranged. Survivors keep
      # their stored order; newly chosen widgets append after them.
      #
      # `survivors | submitted` is set-equal to `submitted`: what was stored
      # decides ORDER, never membership. The union also dedupes, so a payload
      # naming one key twice cannot reach `insert_all` as two rows colliding on
      # one unique index, which Postgres refuses outright.
      #
      # A re-chosen widget appends rather than returning to its old slot: absence
      # of a row means "off", so "removed" and "re-added" are the same gesture
      # twice.
      #
      # A newly chosen widget gets no size — "I have no opinion about how big
      # this is", which is how a picker's tick-box behaves. A SURVIVOR keeps
      # whatever size it already had stored: `arrange` is a full reconcile, so
      # without carrying the old size forward here, every `choose` would quietly
      # reset every widget back to its own default. Ticking a box cannot resize,
      # but neither can leaving one ticked.
      #
      # Takes WIDGETS, not keys — see `arrange`.
      def choose(widgets)
        by_key = widgets.index_by(&:key)

        rows.transaction do
          lock_rows
          current_sizes = rows.pluck(:widget_key, :size).to_h
          survivors = stored_keys & by_key.keys

          arrange((survivors | by_key.keys).map do |key|
            { widget: by_key.fetch(key), size: current_sizes[key] }
          end)
        end
      end

      # Reconcile to exactly `layout` — an ordered list of `{ widget:, size: }`,
      # where POSITION IS THE INDEX and a missing size means "no opinion".
      #
      # WIDGETS, not keys. A key is a string and strings arrive from `params`; a
      # widget comes from looking one up in the already-authorized set. The
      # honest claim is that an unauthorized widget cannot get here BY ACCIDENT —
      # not that it cannot get here.
      #
      # An EMPTY layout is a reset, which is what an emptied grid means: no rows
      # means "never chose", so the next read restores every authorized widget.
      def arrange(layout)
        rows.transaction do
          lock_rows
          rows.delete_all

          next if layout.empty?

          # One timestamp for the whole write. Stamping inside `row_for` gave the
          # rows of a single logical write microsecond-jittered `created_at`s.
          now = Time.current
          Bali::DashboardWidget.insert_all(
            layout.map.with_index { |item, index| row_for(item, index, now) }
          )
        end
      end

      # "Restore defaults" and an emptied grid are the same gesture. No explicit
      # transaction: one `DELETE` is already atomic, and it locks what it matches.
      def reset
        rows.delete_all
      end

      private

      attr_reader :owner, :context, :dashboard_key, :offering

      # The ONLY place the scope is spelled. Six method bodies re-spelling
      # `where(owner:, context:, dashboard_key:)` is a parameter list describing
      # an object nobody had made.
      def rows
        Bali::DashboardWidget.where(owner: owner, context: context,
                                    dashboard_key: dashboard_key)
      end

      # What this DOES buy: two requests that both find existing rows are
      # serialised, so neither sees the other half-written.
      #
      # What it does NOT buy, stated plainly because the name suggests otherwise:
      #
      #   - `FOR UPDATE` can only lock rows that ALREADY EXIST. On a first-ever
      #     `choose`, the scope is empty, there is nothing to lock, and two
      #     concurrent writers proceed completely unserialised.
      #   - It does not prevent a lost update even when it does lock. Each caller
      #     computes its target state from ITS OWN request, so the later commit
      #     wins wholesale — and because `delete_all` runs before `insert_all`,
      #     the loser's row is gone before the unique index could object. No
      #     exception, no conflict: it simply vanishes.
      #
      # Exposure is bounded to one owner racing themselves (two tabs, a retried
      # request), and the grid controller already serialises its own writes
      # client-side. A host that needs more should reach for an advisory lock
      # keyed on the scope — `pg_advisory_xact_lock` serialises writers even when
      # zero rows exist, which row locking structurally cannot. Not done here
      # because it is Postgres-only and this engine runs on whatever the host has.
      def lock_rows
        rows.lock.pluck(:id)
      end

      def row_for(item, index, now)
        {
          owner_type: owner.class.polymorphic_name, owner_id: owner.id,
          context: context, dashboard_key: dashboard_key,
          widget_key: item[:widget].key, position: index,
          size: item[:size].presence&.to_s,
          created_at: now, updated_at: now
        }
      end
    end
  end
end
