# frozen_string_literal: true

module Bali
  # #721 — archiving for a host model:
  #
  #   class Document < ApplicationRecord
  #     include Bali::Archivable
  #     archivable successor_required_for: %i[replaced]
  #   end
  #
  #   document.archive!(by: user, reason: :replaced, successor: other)
  #   Document.not_archived
  #
  # The macro is optional: `include` alone takes the five default reasons, none needing a
  # successor, and makes the model irreversible.
  #
  # One model cannot include this and an `Archivable` of its own: both define `archive!` and
  # `archived?`.
  module Archivable
    extend ActiveSupport::Concern

    DEFAULT_REASONS = %w[replaced no_longer_applicable superseded expired other].freeze

    class AlreadyArchived < StandardError; end
    class NotArchived < StandardError; end
    class NotReversible < StandardError; end

    included do
      class_attribute :archival_reasons, instance_writer: false, default: DEFAULT_REASONS
      class_attribute :archival_successor_required_for, instance_writer: false, default: [].freeze
      class_attribute :archival_reversible, instance_writer: false, default: false

      has_many :archivals, -> { order(created_at: :desc, id: :desc) },
               class_name: "Bali::Archival", as: :archivable, inverse_of: :archivable,
               dependent: :destroy
      has_one :archival, -> { current }, class_name: "Bali::Archival", as: :archivable,
                                         inverse_of: :archivable
    end

    class_methods do
      def archivable(reasons: DEFAULT_REASONS, successor_required_for: [], reversible: false)
        self.archival_reasons = reasons.map(&:to_s).freeze
        self.archival_successor_required_for = successor_required_for.map(&:to_s).freeze
        self.archival_reversible = reversible
      end

      def archived = where(current_archivals.arel.exists)

      def not_archived = where(current_archivals.arel.exists.not)

      # A host relabels a reason for one model under `activerecord.archival_reasons.<model>`.
      def archival_reason_label(reason)
        I18n.t(:"activerecord.archival_reasons.#{model_name.i18n_key}.#{reason}",
               default: :"bali_view.archivals.reasons.#{reason}")
      end

      private

      def current_archivals
        Bali::Archival.current
                      .where(archivable_type: polymorphic_name)
                      .where(Bali::Archival.arel_table[:archivable_id].eq(arel_table[primary_key]))
      end
    end

    def archived? = archival.present?

    def archive!(by: nil, reason: nil, note: nil, successor: nil)
      raise AlreadyArchived if archived?

      archival = transaction(requires_new: true) do
        archivals.create!(archived_by: by, reason: reason, note: note, successor: successor)
      end
      reset_archival
      archival
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyArchived
    end

    def unarchive!(by: nil)
      raise NotReversible unless archival_reversible
      raise NotArchived unless archived?

      current = archival
      current.with_lock do
        raise NotArchived if current.unarchived_at?

        current.update!(unarchived_at: Time.current, unarchived_by: by)
      end
      reset_archival
      current
    end
  end
end
