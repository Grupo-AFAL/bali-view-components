# frozen_string_literal: true

# One chosen dashboard widget: for one owner, in one context, on one dashboard.
#
# A row and nothing more. Reading and writing an arrangement belongs to
# `DashboardWidget::Store`, which owns the scope this table is keyed by.
#
# Bali ships the widget contract (`Bali::Widget::Base`), the card and the
# grid — it ships no store and no table. This model and its `Store` are the
# dummy app acting as the host that owns persistence; see
# `docs/guides/widgets.md` for the contract they implement.
#
# These rows NEVER grant visibility. `Store#widgets` is handed the set the
# owner is already authorized for and can only subset and reorder it. No
# VISIBLE rows means "never chose" — show everything authorized, in catalog
# order. (Rows for widgets the owner cannot currently see survive but do not
# count; see `Store#visible_keys`.)
class DashboardWidget < ApplicationRecord
  belongs_to :owner, polymorphic: true

  validates :dashboard_key, presence: true
  validates :widget_key, presence: true,
                         uniqueness: { scope: %i[owner_type owner_id context dashboard_key] }

  # These guard the ActiveRecord paths only — `Store#arrange` reaches the
  # table through `insert_all`, which bypasses validations and gets its
  # positions from an array index. They exist so a stray `create!` fails with
  # an error naming the column rather than a raw NotNullViolation, and because
  # nothing else stops a negative: there is no CHECK constraint on `position`.
  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Shortcut for a controller's adoption line:
  #   DashboardWidget.store_for(current_user, context: @tenant.id.to_s,
  #                             dashboard_key: "today", offering: offering)
  def self.store_for(owner, dashboard_key:, offering:, context: "")
    Store.new(owner: owner, dashboard_key: dashboard_key, offering: offering, context: context)
  end

  # NOTE: deliberately NOT `acts_as_list`. The gem's contract is dense,
  # contiguous positions within a scope, and this table does not have that: a
  # row for a widget the owner cannot currently see keeps its position while
  # the visible ones renumber around it, so positions can collide and gaps are
  # normal. `insert_at` is the helper anyone would reach for and it does not
  # behave sanely on a scope with duplicates.
  #
  # NOTE: deliberately no `inclusion` validation of `widget_key`. It would make
  # every legacy row unsaveable the day a widget is retired, blocking unrelated
  # saves, and it duplicates a read-side filter that must exist regardless
  # (`Store#widgets` drops unknown keys).
  #
  # The same goes for `size`, which is a string and NOT a Rails enum: the
  # `Bali::Widget::SIZES` vocabulary lives there, this column only caches a
  # name from it, and `with_size` coerces on read. An integer enum would also
  # make the persisted meaning positional — and `SIZES` is not ordered by area,
  # so inserting a `tall` where it belongs would silently relabel every row.

  # `widget_key` is the tie-break, and it is load-bearing rather than tidy. Two
  # rows CAN hold the same position (see above); without a second term SQLite
  # returns those in arbitrary order, which makes `Store#stored_keys`
  # nondeterministic and, through it, `choose`'s "survivors keep their stored
  # order" guarantee unstable.
  scope :ordered, -> { order(:position, :widget_key) }
end
