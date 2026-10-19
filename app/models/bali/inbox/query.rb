# frozen_string_literal: true

module Bali
  module Inbox
    # Everything waiting on one person, across every registered provider. Public, so a host can
    # build on it — gobierno-corporativo's team view runs it once per team member.
    class Query
      # Items are sorted in Ruby across providers, so each one is fetched only this deep.
      FETCH_CAP = 100
      BANDS = %i[overdue this_week later].freeze

      attr_reader :user

      def initialize(user)
        @user = user
        @providers = Bali::Inbox.providers
      end

      def count = counts_by_kind.values.sum

      def counts_by_kind
        @counts_by_kind ||= @providers.to_h { |_module_key, provider| [ provider.kind.to_sym, provider.pending_count_for(user) ] }
      end

      def modules = @providers.map(&:first).uniq

      def items(module_key: nil, kind: nil)
        @providers
          .select { |entry_module, provider| matches?(entry_module, provider, module_key, kind) }
          .flat_map { |entry_module, provider| fetch(entry_module, provider) }
          .sort_by { |item| sort_key(item) }
      end

      # Known once `items` has run.
      def capped? = @capped.present?

      # The item at `/inbox/items/:kind/:gid`, or nil when it is not pending for this user. The
      # record is looked up only inside that kind's own `pending_for`, and compared by its full
      # GlobalID, so a gid of another model with a pending id reaches nothing.
      def find(kind, gid_param)
        module_key, provider = @providers.find { |_module_key, entry| entry.kind.to_s == kind.to_s }
        gid = GlobalID.parse(gid_param.to_s) if provider
        return if gid.nil?

        scope = provider.pending_for(user)
        candidates = scope.respond_to?(:where) ? scope.where(id: gid.model_id) : scope
        record = candidates.detect { |candidate| candidate.to_global_id.to_s == gid.to_s }
        record && provider.build_items([ record ], user: user).first.with(module_key: module_key)
      end

      private

      def matches?(entry_module, provider, module_key, kind)
        (module_key.nil? || entry_module == module_key.to_sym) && (kind.nil? || provider.kind.to_sym == kind.to_sym)
      end

      def fetch(module_key, provider)
        records = provider.pending_for(user).first(FETCH_CAP + 1)
        (@capped ||= []) << provider.kind if records.size > FETCH_CAP

        provider.build_items(records.first(FETCH_CAP), user: user).map { |item| item.with(module_key: module_key) }
      end

      def sort_key(item)
        due = item.due_time
        [ BANDS.index(item.band), due ? 0 : 1, due.to_f, item.title.to_s ]
      end
    end
  end
end
