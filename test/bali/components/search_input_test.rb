# frozen_string_literal: true

require "test_helper"

class BaliSearchInputComponentTest < ComponentTestCase
  def setup
    @form = Bali::Utils::DummyFilterForm.new
  end


  def render_component(**options)
    render_inline(Bali::SearchInput::Component.new(form: @form, field: :name, **options))
  end

  #

  def test_default_rendering_renders_the_search_input_container
    render_component
    assert_selector("div.search-input-component")
  end

  def test_default_rendering_renders_input_with_daisyui_classes
    render_component
    assert_selector("input.input.input-bordered")
  end

  def test_default_rendering_renders_submit_button_with_search_icon
    render_component
    assert_selector("button.btn.btn-primary.join-item")
    assert_selector("button svg")
  end

  def test_default_rendering_uses_join_layout_for_input_and_button
    render_component
    assert_selector("div.form-control.join")
    assert_selector("div.join-item", count: 2)
  end

  def test_default_rendering_generates_correct_input_id
    render_component
    assert_selector("input#q_name")
  end

  def test_default_rendering_generates_correct_input_name
    render_component
    assert_selector('input[name="q[name]"]')
  end
  #

  def test_with_auto_submit_true_hides_the_submit_button
    render_component(auto_submit: true)
    assert_no_selector("button")
  end

  def test_with_auto_submit_true_removes_join_classes
    render_component(auto_submit: true)
    assert_selector("div.form-control")
    assert_no_selector("div.join")
  end

  def test_with_auto_submit_true_adds_stimulus_action_for_auto_submit
    render_component(auto_submit: true)
    assert_selector('input[data-action="submit-on-change#submit"]')
  end
  #

  def test_placeholder_uses_i18n_default_placeholder
    render_component
    assert_selector("input[placeholder]")
  end

  def test_placeholder_allows_custom_placeholder
    render_component(placeholder: "Find users...")
    assert_selector('input[placeholder="Find users..."]')
  end
  #

  def test_custom_classes_allows_adding_custom_input_classes
    render_component(class: "w-64")
    assert_selector("input.input.input-bordered.w-64")
  end
  #

  def test_submit_button_options_accepts_custom_submit_button_classes
    render_component(submit: { class: "btn-lg" })
    assert_selector("button.btn.btn-primary.join-item.btn-lg")
  end

  def test_submit_button_options_accepts_data_attributes_on_submit_button
    render_component(submit: { data: { testid: "search-btn" } })
    assert_selector('button[data-testid="search-btn"]')
  end
  #

  def test_frozen_constants_defines_base_input_classes
    assert_equal("input input-bordered", Bali::SearchInput::Component::BASE_INPUT_CLASSES)
  end

  def test_frozen_constants_defines_base_button_classes
    assert_equal("btn btn-primary join-item", Bali::SearchInput::Component::BASE_BUTTON_CLASSES)
  end

  def test_frozen_constants_defines_container_class
    assert_equal("search-input-component w-full", Bali::SearchInput::Component::CONTAINER_CLASS)
  end
end
