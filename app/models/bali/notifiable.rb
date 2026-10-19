# frozen_string_literal: true

module Bali
  # #1512 — a model notices can be about.
  #
  #   class Signature < ApplicationRecord
  #     include Bali::Notifiable
  #   end
  #
  #   signature.notify(recipient: approver, kind: :signature_assigned, message: "…",
  #                    actor: requester, action_url: signature_path(signature))
  module Notifiable
    extend ActiveSupport::Concern

    included do
      has_many :notices, class_name: "Bali::Notice", as: :notifiable, dependent: :destroy
    end

    # Nothing for a blank recipient. With an `idempotency_key` already used, the notice it named
    # comes back instead of a second one.
    #
    # The savepoint is what lets a caller's own transaction go on: in Postgres the rejected
    # INSERT aborts the transaction around it, and the `find_by!` below would fail with it.
    def notify(recipient:, kind:, message:, actor: nil, action_url: nil, idempotency_key: nil)
      return if recipient.blank?

      Bali::Notice.transaction(requires_new: true) do
        notices.create!(recipient: recipient, kind: kind, message: message, actor: actor,
                        action_url: action_url, idempotency_key: idempotency_key)
      end
    rescue ActiveRecord::RecordNotUnique
      raise if idempotency_key.nil?

      Bali::Notice.find_by!(idempotency_key: idempotency_key)
    end
  end
end
