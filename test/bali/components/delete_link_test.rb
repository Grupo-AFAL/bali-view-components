# frozen_string_literal: true

require "test_helper"

class BaliDeleteLinkComponentTest < ComponentTestCase
  def setup
    @options = { href: "/delete-url" }
  end


  def component
    Bali::DeleteLink::Component.new(**@options)
  end


  def test_renders_a_delete_link
    render_inline(component)
    assert_selector("button.text-error.btn-ghost", text: "Delete")
    assert_selector("[data-turbo-confirm='Are you sure?']")
    assert_selector("[action='/delete-url']")
  end

  def test_overrides_the_link_name
    @options.merge!(name: "Cancel")
    render_inline(component)
    assert_selector("button.text-error.btn-ghost", text: "Cancel")
  end

  def test_overrides_the_link_confirm_message
    @options.merge!(confirm: "Continue?")
    render_inline(component)
    assert_selector("[data-turbo-confirm='Continue?']")
  end

  def test_add_a_css_class_to_the_link
    @options.merge!(class: "btn-lg")
    render_inline(component)
    assert_selector("button.text-error.btn-ghost.btn-lg")
  end

  def test_raises_an_error_without_model_or_href
    @options.merge!(href: nil)
    assert_raises(Bali::DeleteLink::Component::MissingURL) { render_inline(component) }
  end



  def test_renders_a_delete_link_with_custom_form_classes
    @options.merge!(form_class: "bg-success")
    render_inline(component)
    assert_selector("button.text-error.btn-ghost", text: "Delete")
    assert_selector("form.inline-block.bg-success")
  end
  #

  Bali::DeleteLink::Component::SIZES.each do |size, css_class|
  next if css_class.blank?

  define_method("test_sizes_applies_#{size}_#{size}_class") do
    @options.merge!(size: size)
    render_inline(component)
    assert_selector("button.btn.#{css_class}")
  end
  end

  #

  def test_icon_renders_with_icon_when_icon_true
    @options.merge!(icon: true)
    render_inline(component)
    assert_selector("button .icon-component")
    assert_selector("button", text: "Delete")
  end

  def test_icon_does_not_render_icon_by_default
    render_inline(component)
    assert_no_selector(".icon-component")
  end
  #

  def test_skip_confirm_skips_confirmation_when_skip_confirm_true
    @options.merge!(skip_confirm: true)
    render_inline(component)
    assert_no_selector("[data-turbo-confirm]")
  end
  #

  def test_authorization_does_not_render_when_authorized_false
    @options.merge!(authorized: false)
    render_inline(component)
    assert_no_selector("button")
    assert_no_selector("form")
  end

  def test_authorization_renders_when_authorized_true_default
    render_inline(component)
    assert_selector("button")
  end
  #

  def test_block_content_uses_block_content_as_name
    render_inline(component) { "Remove Item" }
    assert_selector("button", text: "Remove Item")
  end
  #

  def test_with_active_record_model_renders_a_delete_link
    render_inline(component)
    assert_selector("button.text-error.btn-ghost", text: "Delete")
    assert_selector("[action='/delete-url']")
  end

  def test_with_active_record_model_overrides_the_default_model_href
    @options.merge!(href: "/delete-url")
    render_inline(component)
    assert_selector("[action='/delete-url']")
  end
  #

  def test_when_the_hover_card_link_component_is_in_use_renders_a_delete_link_disabled
    @options.merge!(disabled: true)
    render_inline(component)
    assert_selector('[disabled="disabled"]')
  end

  def test_when_the_hover_card_link_component_is_in_use_applies_btn_disabled_class_when_disabled
    @options.merge!(disabled: true)
    render_inline(component)
    assert_selector("a.btn-disabled")
  end

  def test_when_the_hover_card_link_component_is_in_use_preserves_custom_classes_when_disabled
    @options.merge!(disabled: true, class: "custom-class")
    render_inline(component)
    assert_selector("a.btn-disabled.custom-class")
  end
end
