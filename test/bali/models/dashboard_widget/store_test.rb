# frozen_string_literal: true

require "test_helper"

class BaliDashboardWidgetStoreTest < ActiveSupport::TestCase
  def self.widget(key, size)
    # `ValueBase`, not `Base` directly: a widget IS one of the four patterns.
    # The store only ever reads keys and sizes, so the figure is a constant.
    Class.new(Bali::Widget::ValueBase) do
      supports(*Bali::Widget::SIZES)
      default_size size
      define_singleton_method(:key) { key }
      define_singleton_method(:title) { key }
      value { 0 }
    end
  end

  ALPHA = widget("alpha", :small)
  BRAVO = widget("bravo", :medium)
  CHARLIE = widget("charlie", :large)

  # No fixtures in this repo; the house pattern is an inline create.
  # See test/bali/models/saved_view_test.rb.
  def owner
    @owner ||= User.create!(name: "Ana")
  end

  def offering = [ ALPHA.new, BRAVO.new, CHARLIE.new ]

  def store(offer: offering)
    Bali::DashboardWidget::Store.new(owner: owner, context: "1",
                                     dashboard_key: "today", offering: offer)
  end

  def keys_of(widgets) = widgets.map(&:key)

  def rows_by_key
    Bali::DashboardWidget.where(owner: owner, context: "1", dashboard_key: "today")
                         .index_by(&:widget_key)
  end

  # THE OFFERING IS THE FEATURE'S SECURITY PROPERTY — a submitted key becomes a
  # widget only by being found in it — and until the Store gated it, that
  # property rested on every host remembering one `authorized_for` call. A host
  # passing its raw catalogue persisted and rendered widgets whose `authorized?`
  # was false, silently.
  def test_the_store_gates_the_offering_it_is_handed
    hidden = Class.new(Bali::Widget::ValueBase) do
      def self.key = "payroll"
      value { 999 }
      def authorized? = false
    end.new

    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new, hidden ])
    store.arrange([ Bali::Widget::Placement.new(widget: hidden, size: :small), Bali::Widget::Placement.new(widget: ALPHA.new, size: :small) ])

    assert_equal [ "alpha" ], store.stored_keys
    assert_equal [ "alpha" ], store.widgets.map(&:key)
  end

  # THE SHAPE A CONTROLLER HAS — `params.expect(widgets: [[:key, :size]])`
  # verbatim, with no lookup done. That lookup is the offering gate, and it
  # belongs on this side of it.
  def test_arrange_takes_key_and_size_hashes
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                             offering: [ ALPHA.new, CHARLIE.new ])

    store.arrange([ { key: "charlie", size: "large" }, { key: "alpha", size: nil } ])

    assert_equal [ "charlie", "alpha" ], store.stored_keys
    assert_equal [ [ "charlie", "large" ], [ "alpha", "small" ] ],
                 store.widgets.map { |placement| [ placement.key, placement.size.to_s ] }
  end

  # An unauthorized, retired or hand-edited key finds nothing in the offering
  # and is dropped — which is the whole reason a controller may hand this raw
  # strings in the first place.
  def test_arrange_drops_an_item_whose_key_is_not_offered
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])

    store.arrange([ { key: "payroll", size: "large" }, { key: "alpha", size: "small" } ])

    assert_equal [ "alpha" ], store.stored_keys
  end

  # STRING KEYS TOO. `ActionController::Parameters` is indifferent, but a layout
  # rebuilt from parsed JSON or a CSV import is not — and reading `item[:key]`
  # off one would give nil for every row, drop every widget, and leave `arrange`
  # reading the empty result as a RESET. Silent total data loss, from a hash
  # spelled the other way.
  def test_arrange_reads_string_keyed_items
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                             offering: [ ALPHA.new, CHARLIE.new ])

    store.arrange([ { "key" => "charlie", "size" => "large" }, { "key" => "alpha" } ])

    assert_equal [ "charlie", "alpha" ], store.stored_keys
    assert_equal [ "large", "small" ], store.widgets.map { |placement| placement.size.to_s }
  end

  # An unpermitted `Parameters` is the same mistake made loudly, rather than a
  # `to_h` that quietly returns something usable.
  def test_arrange_refuses_unpermitted_parameters
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])
    unpermitted = ActionController::Parameters.new(widgets: [ { key: "alpha", size: "small" } ])[:widgets]

    assert_raises(ActionController::UnfilteredParameters) { store.arrange(unpermitted) }
  end

  # A READ ROUND-TRIPS. `#widgets` hands back placements and this takes them,
  # so a host that reorders what it read can write it straight back.
  def test_arrange_takes_the_placements_widgets_returned
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                             offering: [ ALPHA.new, CHARLIE.new ])
    store.arrange([ { key: "alpha", size: "small" }, { key: "charlie", size: "large" } ])

    store.arrange(store.widgets.reverse)

    assert_equal [ "charlie", "alpha" ], store.stored_keys
    assert_equal [ "large", "small" ], store.widgets.map { |placement| placement.size.to_s }
  end

  # `adopt` makes an implicit default arrangement explicit — same widgets, same
  # order, now as rows the user can drag.
  def test_adopt_writes_the_offering_when_nothing_is_stored
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                             offering: [ ALPHA.new, CHARLIE.new ])
    assert_empty store.stored_keys

    store.adopt

    assert_equal [ "alpha", "charlie" ], store.stored_keys
    assert store.customized?
  end

  # AND LEAVES AN EXISTING ARRANGEMENT ALONE. The button promises to change
  # nothing you can see, so a second press — or a second tab — must not flatten
  # a layout back to catalog order.
  def test_adopt_is_a_no_op_once_anything_is_stored
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                             offering: [ ALPHA.new, CHARLIE.new ])
    store.arrange([ { key: "charlie", size: "large" } ])

    store.adopt

    assert_equal [ "charlie" ], store.stored_keys
    assert_equal [ "large" ], store.widgets.map { |placement| placement.size.to_s }
  end

  # A STORE BUILT WITHOUT THE CONCERN STILL REFUSES A COLLISION. This class is a
  # documented standalone API, and when the key check lived only in the
  # `dashboard_widgets` macro a host skipping it got none: `arrange` wrote one
  # row for the shared key and `#widgets` served one widget's data under the
  # other's stored rows, silently.
  def test_a_store_refuses_an_offering_where_two_classes_share_a_key
    first = Class.new(Bali::Widget::ValueBase) { def self.name = "Reports::Overdue"; value { 111 } }
    second = Class.new(Bali::Widget::ValueBase) { def self.name = "Tasks::Overdue"; value { 222 } }

    error = assert_raises(Bali::Widget::DuplicateKey) do
      Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                       offering: [ first.new, second.new ])
    end

    assert_match(/Reports::Overdue, Tasks::Overdue/, error.message)
  end

  # ON WHAT WAS OFFERED, not on what survived `authorized?`. Checking the gated
  # set makes a code bug into a per-user one: two colliding classes with one
  # role-gated pass for every ordinary user and raise for the first admin,
  # mid-render, in production.
  def test_a_collision_hidden_behind_authorized_is_still_refused
    first = Class.new(Bali::Widget::ValueBase) { def self.name = "Reports::Overdue"; value { 1 } }
    second = Class.new(Bali::Widget::ValueBase) do
      def self.name = "Tasks::Overdue"
      value { 2 }
      def authorized? = false
    end

    assert_raises(Bali::Widget::DuplicateKey) do
      Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                       offering: [ first.new, second.new ])
    end
  end

  # And the same CLASS twice is not a collision. Only two distinct classes
  # deriving one key is the data-integrity bug; a repeated widget is an ordinary
  # submission, which `arrange` dedupes on write.
  def test_a_store_accepts_the_same_widget_class_twice
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                             offering: [ ALPHA.new, ALPHA.new ])
    store.arrange([ { key: "alpha" }, { key: "alpha" } ])

    assert_equal [ "alpha" ], store.stored_keys
  end

  # A ROW FOR A WIDGET THE OWNER CANNOT CURRENTLY SEE SURVIVES A REARRANGE.
  # `arrange` used to `delete_all` and reinsert only the offering, so a widget
  # behind a feature flag lost its row the first time the user dragged anything —
  # permanently, because the owner still had rows and `#widgets` therefore never
  # fell back to defaults. This is the invariant `Bali::DashboardWidget` documents
  # and the reason `scope :ordered` tie-breaks on `widget_key`.
  def test_arrange_keeps_rows_for_widgets_outside_the_offering
    hidden = Class.new(Bali::Widget::ValueBase) { def self.key = "flagged"; value { 2 } }

    with_flag = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                                 offering: [ ALPHA.new, hidden.new ])
    with_flag.arrange([ { key: "alpha" }, { key: "flagged" } ])
    assert_equal %w[alpha flagged], with_flag.stored_keys

    # The flag goes off, so `flagged` leaves the offering — and the user drags.
    without = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])
    without.arrange([ { key: "alpha" } ])

    assert_equal [ "alpha" ], without.widgets.map(&:key), "it must not RENDER while hidden"
    assert_includes without.stored_keys, "flagged", "but its row must survive"

    # And it comes back when the flag does.
    restored = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                                offering: [ ALPHA.new, hidden.new ])
    assert_includes restored.widgets.map(&:key), "flagged"
  end

  # THE MEMO MUST NOT OUTLIVE A WRITE. The picker asks `visible_keys` once per
  # offered widget, so `stored_keys` is memoised — but the same Store is read
  # before and after its own `arrange`, and a bare `||=` answers the second read
  # with what was there before the write.
  def test_stored_keys_is_re_read_after_a_write
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d",
                                             offering: [ ALPHA.new, CHARLIE.new ])
    assert_empty store.stored_keys

    store.arrange([ { key: "alpha" } ])
    assert_equal [ "alpha" ], store.stored_keys, "stale after arrange"

    store.choose([ CHARLIE.new ])
    assert_equal [ "charlie" ], store.stored_keys, "stale after choose"

    store.reset
    assert_empty store.stored_keys, "stale after reset"
  end

  # And it really is memoised WITHIN a read, which is what the picker needs.
  def test_stored_keys_is_read_once_per_store
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])
    store.arrange([ { key: "alpha" } ])

    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      5.times { store.visible_keys }
    end

    assert_equal 1, queries, "the picker asks once per offered widget"
  end

  # `choose` used to read the same scope twice inside one transaction — its own
  # `(widget_key, size)` and then `arrange`'s `(widget_key, created_at)`. One
  # SELECT serves both, and this pins it: the rows are already in hand there,
  # which is the only reason `reconcile` takes `born:` rather than querying.
  def test_choose_reads_the_rows_once
    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])
    store.arrange([ { key: "alpha" } ])

    selects = 0
    counter = ->(*, payload) {
      selects += 1 if payload[:sql].start_with?("SELECT") && payload[:name] != "SCHEMA"
    }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      store.choose([ ALPHA.new ])
    end

    assert_equal 1, selects
  end

  # `choose` gates on its own too, not only `arrange`. A picker submits
  # membership rather than a layout, so it reaches a different method and would
  # otherwise be an unguarded second door into the same table.
  def test_choose_drops_a_widget_the_owner_cannot_see
    hidden = Class.new(Bali::Widget::ValueBase) do
      def self.key = "payroll"
      value { 999 }
      def authorized? = false
    end.new

    store = Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ ALPHA.new ])
    store.choose([ ALPHA.new, hidden ])

    assert_equal [ "alpha" ], store.stored_keys
  end

  # Bali does NOT memoise for a host: the default is a constant, and a host whose
  # rule is expensive knows that where Bali cannot. What matters is that the
  # gating boundaries are few and named, not that they are one.
  def test_each_gating_boundary_asks_once
    calls = 0
    widget = ALPHA.new
    widget.define_singleton_method(:authorized?) { calls += 1; true }

    Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "d", offering: [ widget ])

    assert_equal 1, calls
  end

  def test_offering_is_required
    assert_raises(ArgumentError) do
      Bali::DashboardWidget::Store.new(owner: owner, dashboard_key: "today")
    end
  end

  def test_with_no_rows_it_returns_the_whole_offering_in_catalog_order
    assert_equal %w[alpha bravo charlie], keys_of(store.widgets)
    refute_predicate store, :customized?
  end

  def test_arrange_stores_order_and_size
    store.arrange([ Bali::Widget::Placement.new(widget: CHARLIE.new, size: "large"), Bali::Widget::Placement.new(widget: ALPHA.new) ])

    stored = store.widgets

    assert_equal %w[charlie alpha], keys_of(stored)
    assert_equal :large, stored.first.size
    # No size submitted means "no opinion": the widget renders at its own.
    assert_equal :small, stored.last.size
    assert_predicate store, :customized?
  end

  # `arrange` is `delete_all` + `insert_all`, so without carrying them forward a
  # widget that has sat on the dashboard for a year would get a fresh
  # `created_at` every time anything is dragged — and "when did you first add
  # this widget?" would be permanently unanswerable from this table.
  def test_a_rearrange_preserves_when_a_widget_was_first_added
    travel_to Time.zone.local(2026, 1, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new), Bali::Widget::Placement.new(widget: BRAVO.new) ])
    end

    travel_to Time.zone.local(2026, 6, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: BRAVO.new), Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    born = rows_by_key.transform_values(&:created_at)

    assert_equal Time.zone.local(2026, 1, 1), born["alpha"]
    assert_equal Time.zone.local(2026, 1, 1), born["bravo"]
  end

  # The other half: a widget that was NOT there is genuinely new, and dating it
  # to the arrangement it first appeared in is the whole point of keeping these.
  def test_a_newly_added_widget_is_dated_now_not_backfilled
    travel_to Time.zone.local(2026, 1, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    travel_to Time.zone.local(2026, 6, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new), Bali::Widget::Placement.new(widget: CHARLIE.new) ])
    end

    born = rows_by_key.transform_values(&:created_at)

    assert_equal Time.zone.local(2026, 1, 1), born["alpha"]
    assert_equal Time.zone.local(2026, 6, 1), born["charlie"]
  end

  # `updated_at` is the opposite promise: the row really was just rewritten.
  def test_a_rearrange_still_stamps_updated_at
    travel_to Time.zone.local(2026, 1, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    travel_to Time.zone.local(2026, 6, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    assert_equal Time.zone.local(2026, 6, 1), rows_by_key["alpha"].updated_at
  end

  # Removing a widget and adding it back is "off" then "on", not a restoration:
  # `reset` and an emptied grid both drop the rows outright, so there is nothing
  # left to carry a birthday forward from.
  def test_a_widget_removed_and_re_added_is_dated_from_its_return
    travel_to Time.zone.local(2026, 1, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    travel_to Time.zone.local(2026, 3, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: BRAVO.new) ])
    end

    travel_to Time.zone.local(2026, 6, 1) do
      store.arrange([ Bali::Widget::Placement.new(widget: BRAVO.new), Bali::Widget::Placement.new(widget: ALPHA.new) ])
    end

    assert_equal Time.zone.local(2026, 6, 1), rows_by_key["alpha"].created_at
    assert_equal Time.zone.local(2026, 3, 1), rows_by_key["bravo"].created_at
  end

  def test_arrange_is_a_full_reconcile_not_an_append
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new), Bali::Widget::Placement.new(widget: BRAVO.new) ])
    store.arrange([ Bali::Widget::Placement.new(widget: BRAVO.new) ])

    assert_equal %w[bravo], keys_of(store.widgets)
  end

  def test_a_retired_size_falls_back_to_the_widget_s_own
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new, size: "enormous") ])

    assert_equal :small, store.widgets.first.size
  end

  # ---- what the `size` column means ------------------------------------------
  #
  # EVERY WRITE STORES A CONCRETE NAME. `Placement` resolves an omitted or
  # retired size to the widget's `default_size` at construction, and that is what
  # is persisted — so an arrangement is FROZEN at the sizes its owner was shown,
  # and changing a widget's `default_size` later moves new dashboards without
  # rearranging existing ones under their owners.
  #
  # The column is nullable anyway, for rows Bali did not write. These tests exist
  # because that gap between "nullable" and "never written null" is exactly the
  # kind of thing a migration comment starts lying about.

  def test_an_omitted_size_is_stored_as_the_widgets_default
    store.arrange([ { key: "charlie", size: "large" }, { key: "alpha", size: nil } ])

    assert_equal "large", rows_by_key["charlie"].size
    assert_equal "small", rows_by_key["alpha"].size
  end

  # A retired name is not stored either: it falls back for rendering, and the
  # fallback is what gets written, so the dead name does not survive one drag.
  def test_a_retired_size_is_stored_as_the_widgets_default
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new, size: "enormous") ])

    assert_equal "small", rows_by_key["alpha"].size
  end

  def test_adopt_stores_each_widgets_default_size
    store.adopt

    assert_equal({ "alpha" => "small", "bravo" => "medium", "charlie" => "large" },
                 rows_by_key.transform_values(&:size))
  end

  # THE OTHER HALF OF THE SAME PROMISE. A dashboard is frozen at the sizes its
  # owner was shown, so raising a widget's `default_size` must NOT move a card
  # they already have — only a dashboard that has not been written yet.
  def test_raising_a_default_size_leaves_an_existing_dashboard_alone
    klass = self.class.widget("delta", :small)
    offer = -> { [ klass.new ] }
    Bali::DashboardWidget::Store.new(owner: owner, context: "1", dashboard_key: "today",
                                     offering: offer.call).adopt

    klass.default_size :large

    reread = Bali::DashboardWidget::Store.new(owner: owner, context: "1",
                                              dashboard_key: "today", offering: offer.call)

    assert_equal :small, reread.widgets.first.size
  end

  # A REPLACEMENT STORE'S OWN PLACEMENT TYPE IS STILL A PLACEMENT.
  # `Bali::Testing::StoreContract` asks only that a placement RESPOND to
  # `widget`/`size`/`key`, and the guide tells that host to write
  # `store.arrange(store.widgets)` — so a type check against Bali's own class
  # sent every one of those items down the wire branch, where `to_h` has no
  # `:key`. Every item dropped, the empty result read as a RESET, and the
  # `delete_all` already committed: the round-trip the guide recommends wiped
  # the dashboard, silently, in a host that had passed the contract.
  def test_it_accepts_a_placement_from_a_replacement_store
    # Shaped like Bali's own: `key` is DERIVED from the widget rather than being
    # a field, so it is absent from `to_h` — which is exactly what made the wire
    # branch drop the whole layout instead of raising.
    foreign = Data.define(:widget, :size) do
      def key = widget.key
    end

    store.arrange([ foreign.new(widget: CHARLIE.new, size: "large"),
                    foreign.new(widget: ALPHA.new, size: nil) ])

    assert_equal %w[charlie alpha], keys_of(store.widgets)
    assert_equal "large", rows_by_key["charlie"].size
  end

  # And the wire branch still owns everything that does NOT carry a widget —
  # including a plain Hash, which answers `respond_to?(:key)` because `Hash#key`
  # looks up by value. Asking that question instead would raise `ArgumentError`
  # on the commonest input there is.
  def test_a_hash_is_still_read_as_a_wire_item
    store.arrange([ { key: "charlie", size: "large" } ])

    assert_equal %w[charlie], keys_of(store.widgets)
  end

  def test_a_stored_key_outside_the_offering_renders_nothing_and_is_not_visible
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new), Bali::Widget::Placement.new(widget: CHARLIE.new) ])

    narrowed = store(offer: [ ALPHA.new ])

    assert_equal %w[alpha], keys_of(narrowed.widgets)
    assert_equal %w[alpha charlie], narrowed.stored_keys
    assert_equal %w[alpha], narrowed.visible_keys
  end

  def test_a_dashboard_of_only_invisible_rows_falls_back_to_the_offering
    store.arrange([ Bali::Widget::Placement.new(widget: CHARLIE.new) ])

    narrowed = store(offer: [ ALPHA.new, BRAVO.new ])

    # No VISIBLE rows means "never chose", so this is defaults, not an empty page
    # — and `customized?` must agree, or the host offers "restore defaults" to
    # someone already looking at them.
    assert_equal %w[alpha bravo], keys_of(narrowed.widgets)
    refute_predicate narrowed, :customized?
  end

  def test_choose_keeps_stored_order_for_survivors_and_appends_the_rest
    store.arrange([ Bali::Widget::Placement.new(widget: CHARLIE.new), Bali::Widget::Placement.new(widget: ALPHA.new) ])
    store.choose([ ALPHA.new, BRAVO.new, CHARLIE.new ])

    assert_equal %w[charlie alpha bravo], keys_of(store.widgets)
  end

  def test_choose_does_not_resize
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new, size: "large") ])
    store.choose([ ALPHA.new, BRAVO.new ])

    assert_equal :large, store.widgets.first.size
  end

  def test_choose_dedupes_so_a_repeated_key_cannot_collide_on_the_unique_index
    store.choose([ ALPHA.new, ALPHA.new ])

    assert_equal %w[alpha], store.stored_keys
  end

  def test_reset_drops_every_row
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    store.reset

    assert_empty store.stored_keys
    assert_equal %w[alpha bravo charlie], keys_of(store.widgets)
  end

  def test_an_empty_arrange_is_a_reset
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])
    store.arrange([])

    assert_empty store.stored_keys
  end

  # `choose`'s own union already dedupes before it calls `arrange`, but
  # `arrange` is a lower-level primitive a host's controller can call
  # directly from params — where nothing guarantees a unique key. Without an
  # explicit dedupe, `insert_all`'s `ON CONFLICT DO NOTHING` silently keeps
  # only the first occurrence and drops the rest with no error.
  def test_arrange_dedupes_a_repeated_key_instead_of_silently_dropping_it
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new, size: "large"), Bali::Widget::Placement.new(widget: ALPHA.new, size: "large") ])

    assert_equal %w[alpha], store.stored_keys
  end

  def test_rows_are_scoped_to_the_context_and_dashboard
    store.arrange([ Bali::Widget::Placement.new(widget: ALPHA.new) ])

    other_context = Bali::DashboardWidget::Store.new(owner: owner, context: "2",
                                                      dashboard_key: "today", offering: offering)
    other_dashboard = Bali::DashboardWidget::Store.new(owner: owner, context: "1",
                                                        dashboard_key: "finance", offering: offering)

    assert_empty other_context.stored_keys
    assert_empty other_dashboard.stored_keys
  end
end
