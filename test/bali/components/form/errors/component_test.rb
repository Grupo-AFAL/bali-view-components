# frozen_string_literal: true

require "test_helper"

class BaliFormErrorsComponentTest < ComponentTestCase
  def setup
    @model = Movie.new
    @model.errors.add(:name, "can't be blank")
    @model.errors.add(:email, "is invalid")
  end

  def test_rendering_when_model_has_no_errors_renders_nothing
    model = Movie.new
    render_inline(Bali::Form::Errors::Component.new(model: model))
    assert_empty(page.text)
  end

  def test_rendering_when_model_has_errors_renders_the_error_messages
    render_inline(Bali::Form::Errors::Component.new(model: @model))
    assert_selector(".alert.alert-error")
    assert_text("Name can't be blank")
    assert_text("Email is invalid")
  end

  def test_rendering_when_model_has_errors_renders_errors_in_a_list
    render_inline(Bali::Form::Errors::Component.new(model: @model))
    assert_selector("ul.list-disc li", count: 2)
  end

  def test_rendering_when_model_has_errors_includes_margin_bottom_by_default
    render_inline(Bali::Form::Errors::Component.new(model: @model))
    assert_selector(".alert.mb-4")
  end

  def test_rendering_with_title_renders_the_title
    render_inline(Bali::Form::Errors::Component.new(model: @model, title: "Please fix these errors:"))
    assert_text("Please fix these errors:")
  end

  def test_rendering_with_custom_classes_applies_custom_classes
    render_inline(Bali::Form::Errors::Component.new(model: @model, class: "my-custom-class"))
    assert_selector(".alert.my-custom-class")
  end
end
