# frozen_string_literal: true

require "test_helper"

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

class BaliFormHelperTest < FormBuilderTestCase
  def setup
    @form_helper = FormHelperTest.new(nil)
  end


  def test_form_with_renders_a_form_with_submit_button_controller
    html = @form_helper.form_with(url: "/", method: "post")
    assert_html(html, 'form[data-controller="submit-button"]')
  end


  def test_form_for_renders_a_form_with_submit_button_controller
    html = @form_helper.form_for(Movie.new, url: "/") { }
    assert_html(html, 'form[data-controller="submit-button"]')
  end
end
