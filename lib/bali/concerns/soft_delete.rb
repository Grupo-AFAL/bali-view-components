# frozen_string_literal: true

module Bali
  module Concerns
    module SoftDelete
      extend ActiveSupport::Concern
      extend ActiveModel::Callbacks

      included do
        scope :active_and_deleted, -> { unscope(where: :deleted_at) }
        scope :active, -> { where(deleted_at: nil) }
        scope :soft_deleted, -> { where.not(deleted_at: nil) }

        define_model_callbacks :soft_delete
      end

      def active?
        deleted_at.blank?
      end

      def soft_deleted?
        deleted_at.present?
      end

      def soft_delete
        run_callbacks :soft_delete do
          update_column(:deleted_at, Time.zone.now)
        end
      end

      def soft_delete!
        run_callbacks :soft_delete do
          update!(deleted_at: Time.zone.now)
        end
      end

      def _soft_delete
        @_soft_delete
      end

      def _soft_delete=(value)
        @_soft_delete = ActiveRecord::Type::Boolean.new.cast(value)

        soft_delete if @_soft_delete
      end
    end
  end
end
