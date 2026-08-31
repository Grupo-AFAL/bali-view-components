# frozen_string_literal: true

module Bali
  # One chosen dashboard widget: for one owner, in one context, on one dashboard.
  # A row and nothing more — reading and writing an arrangement belongs to
  # `Bali::DashboardWidget::Store`.
  #
  # These rows NEVER grant visibility. `Store#widgets` is handed the set the
  # owner is already authorized for and can only subset and reorder it.
  class DashboardWidget < ApplicationRecord
    belongs_to :owner, polymorphic: true

    validates :dashboard_key, presence: true
    validates :widget_key, presence: true,
                           uniqueness: { scope: %i[owner_type owner_id context dashboard_key] }

    # These guard the ActiveRecord paths only — `Store#arrange` writes through
    # `insert_all`, which bypasses validations. They exist so a stray `create!`
    # fails naming the column, and because nothing else stops a negative
    # position: there is no CHECK constraint on it.
    validates :position, presence: true,
                         numericality: { only_integer: true, greater_than_or_equal_to: 0 }
    validates :size, length: { maximum: 32 }

    # NOTE: deliberately NOT `acts_as_list`. The gem assumes dense, contiguous
    # positions within a scope; this table does not have that, since a row for a
    # widget the owner cannot see keeps its position while visible ones renumber
    # around it. Positions can collide and gaps are normal.
    #
    # NOTE: deliberately no `inclusion` validation on `widget_key`. It would make
    # every legacy row unsaveable the day a widget is retired, and it duplicates
    # a read-side filter that has to exist anyway. Same for `size`, which caches a
    # name from `Bali::Widget::SIZES` rather than owning that vocabulary.

    # `widget_key` is the tie-break, and it is load-bearing: two rows can hold the
    # same position, and without a second term Postgres returns them in arbitrary
    # order — making `stored_keys` nondeterministic and `choose`'s "survivors keep
    # their stored order" guarantee unstable.
    scope :ordered, -> { order(:position, :widget_key) }
  end
end
