# frozen_string_literal: true

module Bali
  # #721 — one archival of ANY host record. Created through Bali::Archivable#archive!, which knows
  # the archived model's reasons. On a reversible model a reopened row stays, as history.
  class Archival < ApplicationRecord
    NOTE_MAX_LENGTH = 500

    belongs_to :archivable, polymorphic: true
    belongs_to :archived_by, polymorphic: true, optional: true
    belongs_to :successor, polymorphic: true, optional: true
    belongs_to :unarchived_by, polymorphic: true, optional: true

    scope :current, -> { where(unarchived_at: nil) }

    # On create only: they judge the decision to archive. Reopening an archival whose reason the
    # model has retired since must not fail on it.
    validates :reason, inclusion: { in: ->(archival) { archival.archivable.try(:archival_reasons).to_a } },
                       allow_blank: true, on: :create
    validates :successor_id, presence: true, on: :create, if: :successor_required?
    validate :successor_is_another_record, on: :create
    validates :note, length: { maximum: NOTE_MAX_LENGTH }

    # The form lists successors and the notice names the successor and who archived — host
    # records Bali knows nothing about — by the first of `title` and `name` they answer.
    def self.name_of(record)
      record.try(:title).presence || record.try(:name).presence || "##{record.id}"
    end

    # `value` when it is a path on this origin, else nil: a redirect or an href built from a
    # request parameter must not leave the site (`//host`, `/\host`) or run script (`javascript:`).
    # Browsers drop tab, CR and LF from a URL, so `/<tab>/host` would resolve as `//host`: any
    # control character or whitespace is refused.
    def self.local_path(value)
      return unless value.is_a?(String) && value.start_with?("/") && !value.start_with?("//", "/\\")

      value unless value.match?(/[[:cntrl:][:space:]]/)
    end

    def reason_label
      archivable.class.archival_reason_label(reason) if reason.present?
    end

    private

    def successor_required?
      archivable.try(:archival_successor_required_for).to_a.include?(reason)
    end

    def successor_is_another_record
      errors.add(:successor_id, :invalid) if successor.present? && successor == archivable
    end
  end
end
