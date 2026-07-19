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
end
