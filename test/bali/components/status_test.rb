# frozen_string_literal: true

require "test_helper"

class BaliStatusComponentTest < ComponentTestCase
  OPTIONS = [
    { value: "pending", label: "Pendiente", color: :slate },
    { value: "validated", label: "Validada", color: :green }
  ].freeze

  def test_display_only_renders_static_pill_with_selected_label
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS))
    assert_selector("span.status-component .status-pill.status-pill--static", text: "Validada")
  end

  def test_display_only_does_not_render_a_form_or_buttons
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS))
    assert_no_selector("form")
    assert_no_selector("button")
  end

  def test_named_color_is_applied_as_inline_background_style
    render_inline(Bali::Status::Component.new(selected: "green", options: [ { value: "green", label: "G", color: :green } ]))
    assert_selector('.status-pill[style*="background-color: #16a34a"]')
    assert_selector('.status-pill[style*="color: #fff"]')
  end

  def test_hex_color_is_applied_with_contrasting_text
    render_inline(Bali::Status::Component.new(selected: "x", options: [ { value: "x", label: "X", color: "#ff0000" } ]))
    assert_selector('.status-pill[style*="background-color: #ff0000"]')
    assert_selector('.status-pill[style*="color:"]')
  end

  def test_nil_selected_renders_placeholder_none_state
    I18n.with_locale(:es) do
      render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS))
      assert_selector(".status-pill.status-pill--none", text: "Sin estado")
    end
  end

  def test_custom_placeholder_overrides_default
    render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS, placeholder: "Elegir"))
    assert_selector(".status-pill.status-pill--none", text: "Elegir")
  end

  def test_size_class_is_applied
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, size: :md))
    assert_selector(".status-pill.status--md")
  end

  def test_id_passthrough_lands_on_root_element
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, id: "test_case_1_status"))
    assert_selector("span#test_case_1_status.status-component")
  end

  FORM = { url: "/things/1/status", method: :patch, param: "thing[status]" }.freeze

  def test_editable_renders_a_form_posting_to_the_given_url_and_method
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("form[action='/things/1/status']")
    assert_selector("input[name='_method'][value='patch']", visible: false)
  end

  def test_editable_renders_a_toggle_trigger_wired_to_the_status_controller
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("span.status-component[data-controller='status']")
    assert_selector("button[type='button'][data-status-target='trigger'][data-action='status#toggle'][aria-haspopup='listbox']")
  end

  def test_editable_renders_one_submit_button_per_option_with_name_and_value
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector("div.status-panel[role='listbox'] button[type='submit'][role='option']", count: 2, visible: false)
    assert_selector("button.status-option[name='thing[status]'][value='pending']", text: "Pendiente", visible: false)
    assert_selector("button.status-option[name='thing[status]'][value='validated']", text: "Validada", visible: false)
  end

  def test_editable_marks_the_current_option_as_selected
    render_inline(Bali::Status::Component.new(selected: "validated", options: OPTIONS, form: FORM))
    assert_selector("button.status-option[value='validated'][aria-selected='true']", visible: false)
    assert_selector("button.status-option[value='pending'][aria-selected='false']", visible: false)
  end

  def test_option_rows_carry_their_own_inline_color
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM))
    assert_selector('button.status-option[value="validated"][style*="background-color: #16a34a"]', visible: false)
  end

  def test_readonly_with_form_renders_static_pill_and_no_form
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM, readonly: true))
    assert_selector(".status-pill.status-pill--static")
    assert_no_selector("form")
    assert_no_selector("[data-controller='status']")
  end

  def test_clearable_renders_a_clear_submit_and_a_none_row_when_a_value_is_selected
    render_inline(Bali::Status::Component.new(selected: "pending", options: OPTIONS, form: FORM, clearable: true))
    assert_selector("button.status-pill__clear[type='submit'][name='thing[status]'][value='']")
    assert_selector("button.status-option--none[type='submit'][value='']", visible: false)
  end

  def test_clearable_hides_the_clear_x_when_nothing_is_selected
    render_inline(Bali::Status::Component.new(selected: nil, options: OPTIONS, form: FORM, clearable: true))
    assert_no_selector("button.status-pill__clear")
  end

  def test_color_value_cannot_break_out_of_the_style_attribute
    render_inline(Bali::Status::Component.new(
      selected: "x",
      options: [ { value: "x", label: "X", color: 'red" onmouseover="alert(1)' } ],
      form: { url: "/t", method: :patch, param: "t[s]" }
    ))
    # If the color value broke out of the style attribute, an onmouseover
    # attribute would exist. tag.* escaping keeps the quote inside style.
    assert_no_selector("[onmouseover]")
  end

  def test_selected_value_absent_from_options_falls_back_to_raw_label_and_default_color
    render_inline(Bali::Status::Component.new(selected: "ghost", options: OPTIONS))
    assert_selector('.status-pill.status-pill--static[style*="background-color: #64748b"]', text: "ghost")
  end
end
