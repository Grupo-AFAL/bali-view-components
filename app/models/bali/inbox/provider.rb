# frozen_string_literal: true

module Bali
  module Inbox
    # The contract a host's provider fulfils — gobierno-corporativo's, with `item` added:
    #
    #   class SignaturesProvider
    #     include Bali::Inbox::Provider
    #
    #     def kind = :signature
    #     def icon = "signature"
    #
    #     def pending_for(user)
    #       Signature.where(approver: user, decision: "pending").includes(:signoff)
    #     end
    #
    #     def build_item(signature, user:)
    #       item signature, title: signature.signoff.title, due_at: signature.due_on,
    #                       href: new_signature_decision_path(signature)
    #     end
    #   end
    #
    # `pending_for` returns a relation or an Array, preloaded for `build_item`; the permission
    # early-outs a provider needs live there too.
    module Provider
      extend ActiveSupport::Concern

      included do
        include Rails.application.routes.url_helpers
      end

      def icon = "inbox"

      # Higher first, unlike Solid Queue's. Within each band only: the page and the popover group by
      # band.
      def priority = 0

      # A COUNT on a relation. A provider that can count more cheaply than it lists overrides it.
      def pending_count_for(user) = pending_for(user).size

      # A provider that needs one lookup for the whole batch overrides this rather than
      # `build_item`.
      def build_items(records, user:) = records.map { |record| build_item(record, user: user) }

      private

      def item(record, **fields) = Item.new(kind: kind.to_sym, record: record, **fields)
    end
  end
end
