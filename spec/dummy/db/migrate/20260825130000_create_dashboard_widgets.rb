# frozen_string_literal: true

# One person's dashboard arrangement: which widgets, in what order, at what size.
#
# Bali ships no store and no table for this — the widget contract
# (`Bali::Widget::Base`), the card and the grid are the engine's; persistence
# is always the host's. This is the dummy app acting as that host, and
# `docs/guides/widgets.md` documents the contract this table backs.
#
# `owner` is polymorphic because a host's "owner" could be a `User`, a
# `Member` or an `Employee` — which is also why there is no foreign key
# pointing into the rest of this schema.
#
# These rows NEVER grant visibility. `DashboardWidget::Store` is handed the
# set the owner is already authorized for and can only subset and reorder it.
class CreateDashboardWidgets < ActiveRecord::Migration[8.1]
  def change
    create_table :dashboard_widgets do |t|
      # index: false — the unique index below leads with [owner_type, owner_id]
      # and serves every lookup, so the references default would be redundant.
      t.references :owner, polymorphic: true, null: false, index: false

      # The host's scope for this dashboard — a tenant id, or "" for a
      # single-tenant app. NOT NULL with a default rather than nullable: SQLite
      # and Postgres both treat NULLs as DISTINCT in a unique index, so a
      # nullable column would let a single-tenant host store the same widget
      # twice.
      t.string :context, null: false, default: ""

      # Which dashboard, for a host with more than one ("today", "finance").
      t.string :dashboard_key, null: false

      t.string :widget_key, null: false
      t.integer :position, null: false

      # Nullable on purpose: "no opinion", so the widget renders at the size it
      # was drawn around. A row predating a resize still renders.
      t.string :size

      t.timestamps
    end

    add_index :dashboard_widgets,
              %i[owner_type owner_id context dashboard_key widget_key],
              unique: true, name: "index_dashboard_widgets_uniqueness"
    add_index :dashboard_widgets,
              %i[owner_type owner_id context dashboard_key position],
              name: "index_dashboard_widgets_ordering"
  end
end
