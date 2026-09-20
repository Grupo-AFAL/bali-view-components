# frozen_string_literal: true

module Bali
  # #709 — "I have read and acknowledge" for a host model:
  #
  #   class Document < ApplicationRecord
  #     include Bali::Acknowledgeable
  #   end
  #
  #   @document.acknowledge(user: current_user)
  #   @document.acknowledged_by?(current_user) # => true
  #
  # There is no macro to configure: the only thing the concern asks the model is
  # `version_label`, and it asks with `try`, so a model with no versions works just the same
  # (the acknowledgment ends up with a nil `version_label`).
  #
  # The engine ships NO controller in v1 on purpose: the value of gobierno-corporativo's
  # endpoint is in a `turbo_stream` that renders a view OF THE HOST, and an engine
  # controller cannot answer that without knowing the host's partial. The 20-line recipe is
  # in docs/guides/engine-models.md.
  module Acknowledgeable
    extend ActiveSupport::Concern

    included do
      has_many :acknowledgments, as: :acknowledgeable,
                                 class_name: "Bali::Acknowledgment", dependent: :destroy
    end

    def acknowledged_by?(user)
      acknowledgments.exists?(user: user)
    end

    # Idempotent: acknowledging the SAME version twice returns the acknowledgment that
    # already existed, untouched — the original `acknowledged_at` survives, which is exactly
    # what makes this usable as evidence.
    #
    # When `version_label` changed, on the other hand, this is a NEW act: the person is
    # signing a different text. The label **and the date** are updated.
    #
    # CAREFUL, here it parts from gobierno-corporativo (`acknowledged_at ||= Time.current`,
    # which keeps the old date on re-signing): that row ends up saying that someone signed
    # v2.0 on a date when v2.0 did not exist yet. With only two columns the only coherent
    # reading is "acknowledged_at is when they signed version_label", so they are updated
    # together. The migration guide names it.
    def acknowledge(user:, content_version_id: nil)
      ack = acknowledgments.find_or_initialize_by(user: user)
      return ack if ack.persisted? && ack.version_label == acknowledgeable_version_label

      ack.acknowledged_at = Time.current
      ack.version_label = acknowledgeable_version_label
      ack.content_version_id = content_version_id || derived_content_version_id
      ack.save!
      ack
    rescue ActiveRecord::RecordNotUnique
      # Two clicks at once: the unique index rejects the second INSERT. The row that won
      # says the same thing we were about to write, so returning it IS the correct result.
      acknowledgments.find_by!(user: user)
    end

    private

    def acknowledgeable_version_label
      try(:version_label)
    end

    # Filled in only when the record also carries content history (#707). With `try` because
    # installing the acknowledgment book does not force installing the history: without it
    # this is nil and the column stays empty, which is exactly why it has no foreign key.
    def derived_content_version_id
      try(:content_versions)&.last&.id
    end
  end
end
