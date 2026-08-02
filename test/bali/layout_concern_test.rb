# frozen_string_literal: true

require "test_helper"

class CustomApplicationController < ApplicationController
  include Bali::LayoutConcern
end

class BaliLayoutConcernTest < ActiveSupport::TestCase
  def setup
    @controller = CustomApplicationController.new
  end

  def test_conditionally_skip_layout_when_layout_param_is_false_returns_false
    @controller.params = { layout: "false" }
    refute(@controller.conditionally_skip_layout)
  end

  def test_conditionally_skip_layout_when_layout_param_is_true_returns_the_controller_conditional_layout
    @controller.params = { layout: "true" }
    @controller.class.conditional_layout = "my_layout"
    assert_equal("my_layout", @controller.conditionally_skip_layout)
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
end
