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

      # A provider's items may name a module of their own, so a module with no provider of its own
      # is still one to filter by.
      def modules = Bali.inbox_providers.keys.map(&:to_sym)

      def icon(kind)
        @providers.find { |_module_key, provider| provider.kind.to_s == kind.to_s }&.last&.icon || "inbox"
      end

      def items(module_key: nil, kind: nil)
        @providers
          .select { |_module_key, provider| kind.nil? || provider.kind.to_sym == kind.to_sym }
          .flat_map { |entry_module, provider| fetch(entry_module, provider) }
          .select { |item| module_key.nil? || item.module_key == module_key.to_sym }
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
        record && in_module(provider.build_items([ record ], user: user).first, module_key)
      end

      # `[notifiable_type, notifiable_id]` of every item here with an unread notice that announces
      # it — the «Nuevo» marks — in one query.
      def fresh_keys(items)
        return Set.new if items.empty? || Bali::Notice.announcing_kinds.empty?

        announcing_notices_about(items.map(&:record)).pluck(:notifiable_type, :notifiable_id).to_set
      end

      # Viewing an item is reading what announced it.
      def mark_seen!(item)
        Bali::Notice.mark_read!(announcing_notices_about([ item.record ]))
      end

      private

      def announcing_notices_about(records)
        by_type = records.group_by { |record| record.class.polymorphic_name }
        about = by_type.map { |type, typed| Bali::Notice.where(notifiable_type: type, notifiable_id: typed.map(&:id)) }
                       .reduce(:or)

        Bali::Notice.unread.addressed_to(user).where(kind: Bali::Notice.announcing_kinds).merge(about)
      end

      def fetch(module_key, provider)
        records = provider.pending_for(user).first(FETCH_CAP + 1)
        (@capped ||= []) << provider.kind if records.size > FETCH_CAP

        provider.build_items(records.first(FETCH_CAP), user: user).map { |item| in_module(item, module_key) }
      end

      # A provider whose kind spans modules names each item's own.
      def in_module(item, module_key) = item.module_key ? item : item.with(module_key: module_key)

      def sort_key(item)
        due = item.due_time
        [ BANDS.index(item.band), -priorities.fetch(item.kind), due ? 0 : 1, due.to_f, item.title.to_s ]
      end

      def priorities = @priorities ||= @providers.to_h { |_module_key, provider| [ provider.kind.to_sym, provider.priority ] }
    end
  end
end
