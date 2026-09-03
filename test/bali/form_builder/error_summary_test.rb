# frozen_string_literal: true

require "test_helper"

# `form_with url: ..., scope: :thing` — a form with no model behind it — hands the
# builder `object = false`, not nil. Safe navigation does not catch false, so
# `object&.errors` raised `undefined method 'errors' for false` on the render that
# OPENS the screen (#1111): a 500 for putting an error summary on a non-model form,
# which is the kind of form that most needs one, because there is no model to carry
# the errors.
class BaliFormBuilderErrorSummaryTest < FormBuilderTestCase
  def test_a_form_with_no_model_renders_nothing_instead_of_raising
    assert_equal "", non_model_builder.error_summary
  end

  def test_a_form_with_no_model_renders_nothing_with_a_title_either
    assert_equal "", non_model_builder.error_summary(title: "Corrige lo siguiente:")
  end

  def test_a_model_with_no_errors_renders_nothing
    assert_equal "", builder.error_summary
  end

  def test_a_model_with_errors_renders_the_summary
    resource.errors.add(:name, "is invalid")

    html = builder.error_summary

    assert_html html, "*", text: "Name is invalid"
  end

  def test_the_title_reaches_the_summary
    resource.errors.add(:name, "is invalid")

    html = builder.error_summary(title: "Corrige lo siguiente:")

    assert_html html, "*", text: "Corrige lo siguiente:"
  end

  private

  # What `form_with url:, scope:` builds: no object at all.
  def non_model_builder
    Bali::FormBuilder.new("thing", false, vc_test_controller.view_context, {})
  end

  def builder
    @builder ||= Bali::FormBuilder.new("movie", resource, vc_test_controller.view_context, {})
  end
end
