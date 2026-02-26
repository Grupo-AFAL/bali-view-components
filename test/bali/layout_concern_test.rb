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
end
