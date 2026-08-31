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
    #       assert_bali_store_contract MyDashboardStore.new(owner: user, offering: [Overdue])
    #     end
    #   end
    #
    # SHAPE ONLY. It checks that the eight messages exist and that the four reads
    # answer in the right shapes — not that the semantics are right, which is
    # what a replacement's own tests are for. What it buys is that the list stops
    # being prose: add a method to `Store` without adding it here and the omission
    # is visible, rather than surfacing as a NoMethodError in a host months later.
    module StoreContract
      READS = {
        widgets: Array,
        stored_keys: Array,
        visible_keys: Array
      }.freeze

      WRITES = %i[choose arrange adopt reset].freeze

      def assert_bali_store_contract(store)
        (READS.keys + WRITES + [ :customized? ]).each do |message|
          assert_respond_to store, message,
                            "a dashboard store must answer `#{message}` — see " \
                            "Bali::DashboardWidget::Store for what it means"
        end

        READS.each do |message, type|
          assert_kind_of type, store.public_send(message),
                         "`#{message}` must return #{type}"
        end

        assert_includes [ true, false ], store.customized?, "`customized?` must be a boolean"

        # ARITY, because these are the two a host's controller calls with an
        # argument and the two most likely to be spelled wrong.
        assert_equal 1, store.method(:choose).arity, "`choose` takes the widgets"
        assert_equal 1, store.method(:arrange).arity, "`arrange` takes the layout"
      end
    end
  end
end
