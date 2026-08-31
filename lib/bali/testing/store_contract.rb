# frozen_string_literal: true

module Bali
  module Testing
    # THE CONTRACT A REPLACEMENT STORE MUST MEET. `Bali::DashboardWidget::Store`
    # is the default implementation, not a requirement — a host that already
    # persists dashboards passes its own object and never runs the migration.
    #
    # This exists because that contract was a paragraph of comment for a while,
    # and an unenforced documented interface rots on the first refactor. It is an
    # assertion a replacement runs against itself:
    #
    #   require "bali/testing/store_contract"
    #
    #   class MyDashboardStoreTest < ActiveSupport::TestCase
    #     include Bali::Testing::StoreContract
    #
    #     def test_it_can_stand_in_for_balis_own
    #       assert_bali_store_contract MyDashboardStore.new(owner: user, dashboard_key: "today", offering: [Overdue])
    #     end
    #   end
    #
    # SHAPE ONLY — the eight messages exist, the reads answer usefully, and the
    # two writes can actually be called. Not that the semantics are right, which
    # is what a replacement's own tests are for. What it buys is that the list
    # stops being prose: add a method to `Store` without adding it here and the
    # omission is visible, rather than surfacing as a NoMethodError in a host
    # months later.
    module StoreContract
      MESSAGES = %i[widgets stored_keys visible_keys customized? choose arrange adopt reset].freeze

      # The key arrays are compared against `params[:keys].map(&:to_s)`, so their
      # element type is part of the contract rather than an implementation detail.
      KEY_READS = %i[stored_keys visible_keys].freeze

      def assert_bali_store_contract(store)
        MESSAGES.each do |message|
          assert_respond_to store, message,
                            "a dashboard store must answer `#{message}` — see " \
                            "Bali::DashboardWidget::Store for what it means"
        end

        assert_includes [ true, false ], store.customized?, "`customized?` must be a boolean"

        # PLACEMENTS, not widgets. The controller reads `.widget` and `.size` off
        # each one and matches `.key` against submitted params, so an Array alone
        # says nothing about whether a replacement is usable.
        assert_kind_of Array, store.widgets, "`widgets` must return an Array"
        store.widgets.each do |placement|
          assert_respond_to placement, :widget, "`widgets` returns placements, not widgets"
          assert_respond_to placement, :size
          assert_respond_to placement, :key
        end

        KEY_READS.each do |message|
          keys = store.public_send(message)
          assert_kind_of Array, keys, "`#{message}` must return an Array"
          keys.each { |key| assert_kind_of String, key, "`#{message}` holds strings" }
        end

        # CALLED, not measured. Arity proves nothing about spelling and rejects
        # every delegating wrapper — `delegate`, `def_delegator` and
        # `SimpleDelegator` all produce `def choose(...)`, arity -1 — which is the
        # likeliest replacement of all: someone wrapping Bali's own Store to add a
        # cache or an audit log. An empty layout is the documented reset, so both
        # are safe to run against a real store.
        store.arrange([])
        store.choose([])
      end
    end
  end
end
