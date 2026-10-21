# frozen_string_literal: true

module Bali
  # #1512 — «Pendientes»: what is waiting on one person, read live from the host's models through
  # the providers in `Bali.inbox_providers`. It has no table. Guide: docs/guides/engine-models.md.
  module Inbox
    # `[[module_key, provider], ...]`, in registration order. Built on every call from class
    # names, so a development reload never hands back a stale class.
    def self.providers
      registered = Bali.inbox_providers.flat_map do |module_key, names|
        Array(names).map { |name| [ module_key.to_sym, name.to_s.constantize.new ] }
      end
      check!(registered)
      registered
    end

    def self.check!(registered)
      registered.group_by { |_module_key, provider| provider.kind.to_sym }.each do |kind, entries|
        next if entries.one?

        raise ArgumentError, "Bali.inbox_providers: kind :#{kind} is registered more than once " \
                             "(#{entries.map(&:first).join(', ')})"
      end

      kinds = registered.map { |_module_key, provider| provider.kind.to_sym }
      Bali::Notice.kinds.each_value do |notice_kind|
        next if notice_kind.announces.nil? || kinds.include?(notice_kind.announces)

        raise ArgumentError, "Bali.notice_kinds[:#{notice_kind.name}] announces :#{notice_kind.announces}, " \
                             "which no provider in Bali.inbox_providers has"
      end
    end
    private_class_method :check!
  end
end
