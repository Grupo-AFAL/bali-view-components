# frozen_string_literal: true

require "test_helper"

class CustomApplicationController < ApplicationController
  include Bali::LayoutConcern
end

class BaliLayoutConcernTest < ActiveSupport::TestCase
  def setup
    @controller = CustomApplicationController.new
    @controller.request = ActionDispatch::TestRequest.create
  end

  def test_conditionally_skip_layout_when_layout_param_is_false_returns_false
    @controller.params = { layout: "false" }
    refute(@controller.conditionally_skip_layout)
  end

  def test_conditionally_skip_layout_when_layout_param_is_true_returns_the_controller_conditional_layout
    @controller.params = { layout: "true" }
    @controller.class.conditional_layout = "my_layout"
    assert_equal("my_layout", @controller.conditionally_skip_layout)
  ensure
    @controller.class.conditional_layout = nil
  end

  def test_drawer_request_is_true_only_for_the_overlay_fetch
    @controller.params = { layout: "false" }
    assert(@controller.drawer_request?)

    @controller.params = {}
    refute(@controller.drawer_request?)
  end

  # The predicate is a helper because that is how the page components autodetect `context:`
  # without ever touching `params` themselves.
  def test_drawer_request_is_exposed_to_the_views
    assert_includes(CustomApplicationController._helper_methods, :drawer_request?)
    assert_respond_to(CustomApplicationController.new.view_context, :drawer_request?)
  end

  # #1097. `layout :a_symbol` never reaches `super` from an ApplicationController, because
  # returning nil sends Rails to `layouts/application` — which exists — instead. So the
  # concern has to answer the frame itself or turbo-rails' layout is dead in every app that
  # includes it.
  def test_a_turbo_frame_request_gets_turbo_rails_own_frame_layout
    @controller.params = {}
    @controller.request = frame_request

    assert_equal("turbo_rails/frame", @controller.conditionally_skip_layout)
  end

  def test_the_frame_layout_beats_a_declared_conditional_layout
    @controller.params = {}
    @controller.request = frame_request
    @controller.class.conditional_layout = "admin"

    assert_equal("turbo_rails/frame", @controller.conditionally_skip_layout)
  ensure
    @controller.class.conditional_layout = nil
  end

  # A response headed for a `#main-drawer` does not want even the frame layout's `<html>`.
  def test_a_drawer_fetch_beats_the_frame
    @controller.params = { layout: "false" }
    @controller.request = frame_request

    refute(@controller.conditionally_skip_layout)
  end

  def test_an_ordinary_request_is_not_a_frame_request
    @controller.params = {}

    assert_nil(@controller.conditionally_skip_layout)
  end

  # The trap the fix has to survive: turbo-rails declares the predicate under its own
  # `private`, so the obvious `respond_to?(:turbo_frame_request?)` answers FALSE and the
  # frame branch is never taken. If this ever starts passing without `include_all`, the
  # `true` in the concern's `respond_to?` can go — until then it is load-bearing.
  def test_turbo_rails_keeps_its_predicate_private
    refute_respond_to(@controller, :turbo_frame_request?)
    assert(@controller.respond_to?(:turbo_frame_request?, true))
  end

  private

  def frame_request
    ActionDispatch::TestRequest.create("HTTP_TURBO_FRAME" => "detail")
  end
end
