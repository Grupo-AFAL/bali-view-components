# frozen_string_literal: true

module Bali
  class DashboardWidget
    # One owner's dashboard arrangement in one context: which widgets, in what
    # order, at what size. The only thing that reads or writes
    # `bali_dashboard_widgets` — `Bali::DashboardWidget`, the AR model this
    # class is nested under, is a row and nothing more; see its own comments.
    #
    # NOTE `arrange` is `delete_all` + `insert_all`, so no row survives a
    # rearrange — but `created_at` does: `arrange` reads the existing ones before
    # it deletes and carries each surviving widget's forward, so "when did you
    # first add this widget?" stays answerable across any number of drags. A
    # widget that was absent is dated now, and `updated_at` is always now.
    #
    # `Store` ITSELF is not an ActiveRecord model, deliberately — a plain object
    # scoped to one owner, one context and one dashboard, the same shape as
    # `SavedView::Store`. There is no separate `dashboards` table backing that
    # scope: owner + context + dashboard_key is pure join identity, and a table
    # for it would buy only an owner, a context and two timestamps — bought with
    # a migration and an extra read on every request, for a name we can have for
    # free by scoping `DashboardWidget` rows directly. Promote it the day a
    # dashboard has state of its own.
    #
    # THE CONTRACT a replacement must implement, if a host already persists
    # dashboards elsewhere (an existing table, its own model) and wants to pass
    # that object instead of this one — the same seam `SavedView::Store` proves
    # (a phase-2 team-shared implementation is OTRA clase con este mismo
    # contrato):
    #
    #   - `widgets`         — the offering, subset/reordered/resized by what is stored
    #   - `stored_keys`     — every stored key, including ones the owner cannot see
    #   - `visible_keys`    — stored keys the owner can currently see, in stored order
    #   - `customized?`     — whether there is anything visible to reset
    #   - `choose(widgets)` — membership only; survivors keep stored order and size
    #   - `arrange(layout)` — full reconcile to exactly `layout`
    #   - `reset`           — drop every row
    #
    # This class is the DEFAULT implementation of that contract, not a
    # requirement of it — a host supplying its own never runs
    # `bali:install:migrations:dashboard_widgets`.
    #
    # NOTE `context` here is the SCOPING STRING — a tenant id, or "" for a
    # single-tenant host. It is unrelated to `Bali::Widget::Base#context`, which
    # is the actor object a host's `authorized?` gates against. This class never
    # sees that one.
    class Store
      # The set the owner is being shown right now.
      # State rather than an argument to three methods, because every one of them
      # needs it and all mean the same thing by it.
      #
      # REQUIRED, with no default, and that is deliberate. An empty offer is a
      # valid state (an owner authorized for nothing) but a terrible default:
      # `arrange` would lose its delete half, since `[] - submitted` is `[]`;
      # `choose` would become a no-op; and `widgets` would render nothing. Three
      # wrong behaviours from one forgotten argument, none of them raising.
      # GATED HERE, not merely expected to arrive gated. The offering is the
      # feature's entire security property — a submitted key becomes a widget
      # only by being found in it — and until this line that property depended
      # on every host remembering one call. A host that passed its raw catalogue
      # persisted and rendered widgets whose `authorized?` was false, silently.
      #
      # `authorized_for` is idempotent and memoised, so a host that filters first
      # (as `docs/guides/engine-models.md` still tells it to) pays nothing.
      def initialize(owner:, dashboard_key:, offering:, context: "")
        @owner = owner
        @context = context.to_s
        @dashboard_key = dashboard_key.to_s
        @offering = Bali::Widget.authorized_for(offering)
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
          # One query for both the stored order and the stored sizes, rather
          # than `stored_keys` plus a second `pluck` for sizes — same two
          # facts, one SELECT.
          stored = rows.ordered.pluck(:widget_key, :size).to_h
          survivors = stored.keys & by_key.keys

          arrange((survivors | by_key.keys).map do |key|
            { widget: by_key.fetch(key), size: stored[key] }
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
          # BEFORE the delete, which is the only chance to read them. `arrange`
          # is a reconcile rather than an upsert, so every row is destroyed and
          # rebuilt on every gesture — without carrying these forward a widget
          # that has sat on the dashboard for a year would get a fresh
          # `created_at` each time anything was dragged.
          #
          # This is a second SELECT on the path `choose` already plucks once, and
          # it is deliberately not folded into that one: `arrange` is the
          # lower-level primitive a host's controller can call directly, so it
          # has to hold this invariant on its own rather than trusting a caller
          # to have read the rows for it.
          born = rows.pluck(:widget_key, :created_at).to_h

          rows.delete_all

          next if layout.empty?

          # `choose`'s own union already dedupes before it ever calls here, but
          # `arrange` is the lower-level primitive and a host's controller can
          # reach it directly from params, where nothing guarantees a unique
          # key. Without this, `insert_all` emits `ON CONFLICT DO NOTHING` and
          # silently keeps only the FIRST occurrence of a repeated key,
          # dropping the rest with no error — so dedupe explicitly instead of
          # leaning on that.
          deduped = layout.uniq { |item| item[:widget].key }

          # And gated against the offering, for the same reason as the dedupe
          # above: `arrange` is the primitive a host can reach directly, so it
          # holds its own invariants rather than trusting a caller to have used
          # `Layout.from`. The offering is already authorized by the constructor,
          # so a widget the owner cannot see finds no key here and is dropped —
          # silently, like every other unauthorized key, because a role revoked
          # between render and submit should degrade rather than 422.
          offered = offering.index_by(&:key)
          deduped = deduped.select { |item| offered.key?(item[:widget].key) }

          next if deduped.empty?

          # One timestamp for the whole write. Stamping inside `row_for` gave the
          # rows of a single logical write microsecond-jittered `created_at`s.
          now = Time.current
          Bali::DashboardWidget.insert_all(
            deduped.map.with_index { |item, index| row_for(item, index, now, born) }
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

      # The READ scope. `row_for` below spells the same four columns again on
      # the write side — that one can't be collapsed into this: `insert_all`
      # builds attribute hashes directly, bypassing the AR relation (and its
      # validations) entirely, which is the whole point of using it for a bulk
      # write.
      def rows
        Bali::DashboardWidget.where(owner: owner, context: context,
                                    dashboard_key: dashboard_key)
      end

      def row_for(item, index, now, born)
        key = item[:widget].key

        {
          owner_type: owner.class.polymorphic_name, owner_id: owner.id,
          context: context, dashboard_key: dashboard_key,
          widget_key: key, position: index,
          size: item[:size].presence&.to_s,
          # A widget that was already on the dashboard keeps the moment it
          # arrived; one that was not is genuinely new and is dated now. A
          # widget removed and later re-added is the second case, not the first
          # — absence of a row means "off", so "removed" and "re-added" are the
          # same gesture twice and there is nothing left to carry forward.
          #
          # `updated_at` is always `now`, which is the opposite promise and the
          # true one: the row really was just rewritten.
          created_at: born.fetch(key, now), updated_at: now
        }
      end
    end
  end
end
