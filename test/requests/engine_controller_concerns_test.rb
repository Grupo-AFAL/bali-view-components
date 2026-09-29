# frozen_string_literal: true

require "test_helper"

# #710 — Bali.engine_controller_concerns: the extension point through which a host injects concerns
# into the engine's controllers. Because of isolate_namespace, Bali::ApplicationController does NOT
# inherit from the host's ApplicationController, so `current_user` does not exist there on its own;
# the engine includes each module of the array in a to_prepare. Here prepare! is fired by hand, the
# same way a reload fires it in development or the boot does in production.
class BaliEngineControllerConcernsTest < ActionDispatch::IntegrationTest
  # A realistic concern: it teaches `current_user`, which is exactly what `Bali.saved_views_owner`'s
  # default tries to read. A plain module on purpose (no ActiveSupport::Concern): a plain module
  # would re-fire its `included` hook on every to_prepare if the engine did not remember the
  # inclusion — the counter gives it away.
  module HostSession
    class << self
      attr_accessor :user, :included_count
    end
    self.included_count = 0

    def self.included(_base)
      self.included_count += 1
    end

    def current_user
      HostSession.user
    end
  end

  STORAGE = "movies_index"

  def setup
    @orig_concerns = Bali.engine_controller_concerns
    @orig_owner = Bali.saved_views_owner
    # The engine's real default — the one that returns nil when nobody taught current_user.
    Bali.saved_views_owner = ->(controller) { controller.try(:current_user) }
    HostSession.user = User.create!(name: "Ana")
  end

  def teardown
    Bali.engine_controller_concerns = @orig_concerns
    Bali.saved_views_owner = @orig_owner
    # Ruby does not un-include modules: HostSession stays in the controller's ancestors for the rest
    # of the suite. With `user` at nil, `current_user` goes back to returning nil and the observable
    # behaviour of the other tests does not change.
    HostSession.user = nil
  end

  def test_an_injected_concern_teaches_current_user_to_the_engine_controllers
    Bali.engine_controller_concerns = [ HostSession ]
    Rails.application.reloader.prepare!

    assert_operator Bali::ApplicationController, :<, HostSession

    assert_difference "Bali::SavedView.count", 1 do
      post bali.saved_views_path(storage_id: STORAGE), params: {
        name: "Mías", payload: { "attributes" => {} }.to_json
      }
    end
    assert_response :redirect
    assert_equal HostSession.user, Bali::SavedView.last.owner
  end

  def test_assignment_alone_does_not_include_until_to_prepare_runs
    probe = Module.new
    Bali.engine_controller_concerns = [ probe ]

    refute_operator Bali::ApplicationController, :<, probe

    Rails.application.reloader.prepare!

    assert_operator Bali::ApplicationController, :<, probe
  end

  def test_the_include_is_idempotent_across_repeated_to_prepare_runs
    counter = Module.new do
      @included_count = 0

      def self.included(_base)
        @included_count += 1
      end

      def self.included_count
        @included_count
      end
    end
    Bali.engine_controller_concerns = [ counter ]

    2.times { Rails.application.reloader.prepare! }

    assert_equal 1, counter.included_count
  end
end
