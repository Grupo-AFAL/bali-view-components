# frozen_string_literal: true

module Bali
  # B2 — a saved DataTable view: a NAMED combination of filters, belonging to an owner
  # (polymorphic `owner` — the user today; phase 2 will make owner=team/role without
  # touching the schema) and to ONE listing (`storage_id`). This model + its Store are the
  # DEFAULT implementation of FilterForm's `saved_views_store` contract — an app can still
  # pass its own store and this model never even loads.
  class SavedView < ApplicationRecord
    # The FilterForm defines the payload contract; the model does not trust the UI to send
    # only what was agreed and trims everything else on assignment.
    PAYLOAD_KEYS = Bali::FilterForm::SavedViewsConfiguration::PAYLOAD_KEYS
    NAME_MAX_LENGTH = 60

    belongs_to :owner, polymorphic: true

    validates :storage_id, presence: true
    validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH },
                     uniqueness: { scope: %i[owner_type owner_id storage_id] }

    # Shortcut for the adoption line in a controller:
    #   saved_views_store: Bali::SavedView.store_for(current_user, "users_index")
    def self.store_for(owner, storage_id)
      Store.new(owner: owner, storage_id: storage_id)
    end

    # Bali's UI sends the payload as JSON serialized in a hidden field (Stimulus injects
    # the columns on submit); it also accepts a plain Hash (tests, console).
    def payload=(value)
      value = JSON.parse(value) if value.is_a?(String)
      super(value.is_a?(Hash) ? value.slice(*PAYLOAD_KEYS) : {})
    rescue JSON::ParserError
      super({})
    end
  end
end
