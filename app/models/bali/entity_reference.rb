# frozen_string_literal: true

module Bali
  # #708 — a reference embedded in BlockNote content, materialized as a row so the host can
  # ask "who mentions this record?" without scanning JSON.
  #
  # `Bali::EntityReferenceable` writes them with a minimal diff on every editor save; nobody
  # creates them by hand. `referenceable` is `optional: true` because a reference to a
  # deleted record is STILL valid: it is exactly the broken chip the JS renders.
  class EntityReference < ApplicationRecord
    belongs_to :record, polymorphic: true
    belongs_to :referenceable, polymorphic: true, optional: true

    validates :referenceable_type, presence: true
    validates :referenceable_id, presence: true,
                                 uniqueness: { scope: %i[record_type record_id referenceable_type] }

    scope :of_type, ->(type) { where(referenceable_type: type) }

    # The polymorphic inverse: the references THAT POINT AT this record. It works for any
    # model, whether or not it includes the concern (a referenced user has no reason to know
    # anything about BlockNote).
    scope :to, ->(entity) { where(referenceable_type: entity.class.name, referenceable_id: entity.id) }

    # Reachability according to the host's registry: with no registered type, a present
    # referent is enough. Requires `referenceable` to be loaded (the panels use
    # `includes(:referenceable)`).
    def broken?
      Bali.entity_reference_unreachable?(referenceable_type, referenceable)
    end

    def reachable? = !broken?
  end
end
