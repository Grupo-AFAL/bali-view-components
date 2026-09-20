# frozen_string_literal: true

module Bali
  # #709 — a signature: this person confirmed having read this. It is not created by hand;
  # `Bali::Acknowledgeable#acknowledge` produces it, and that is what knows how to resolve
  # idempotency and the version label.
  #
  # There is no `acknowledgeable_type` whitelist on the model (gobierno-corporativo does have
  # one). Here it is redundant: the engine exposes no controller in v1, so the type never
  # arrives from a request — the host's own model sets it when calling `acknowledge`. If an
  # endpoint ever lands, the whitelist goes in the controller config, as in #707, and not in
  # the model: an `inclusion:` over a constant cannot be configured per app.
  class Acknowledgment < ApplicationRecord
    belongs_to :acknowledgeable, polymorphic: true
    belongs_to :user, polymorphic: true

    validates :acknowledged_at, presence: true
    validates :user_id, uniqueness: {
      scope: %i[acknowledgeable_type acknowledgeable_id user_type]
    }
  end
end
