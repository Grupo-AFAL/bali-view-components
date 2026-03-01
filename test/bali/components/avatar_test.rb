# frozen_string_literal: true

require "test_helper"

class FormHelperTest < ActionView::TestCase
  include Bali::FormHelper
end

class BaliAvatarComponentTest < ComponentTestCase
  def setup
    @options = {}
  end

  def component
    Bali::Avatar::Component.new(**@options)
  end

  def test_display_only_mode_renders_with_src_parameter
    @options.merge!(src: "/avatar.png", size: :lg)
    render_inline(component)
    assert_selector(".avatar")
    assert_selector('img[src*="avatar.png"]')
  end

  def test_display_only_mode_renders_with_default_size_md_and_shape_circle
    @options.merge!(src: "/avatar.png")
    render_inline(component)
    assert_selector(".avatar .w-16.rounded-full")
  end

  def test_with_custom_picture_slot_renders_the_provided_picture_instead_of_src
    @options.merge!(src: "/default-avatar.png")
    render_inline(component) do |c|
      c.with_picture(image_url: "/custom-avatar.png")
    end
    assert_selector('img[src*="custom-avatar.png"]')
    assert_no_selector('img[src*="default-avatar.png"]')
  end

  def test_with_custom_picture_slot_passes_data_attributes_through_to_picture
    render_inline(component) do |c|
      c.with_picture(image_url: "/avatar.png", data: { test: "value" })
    end
    assert_selector('img[data-test="value"]')
  end

  def test_shapes_renders_circle_shape_by_default
    @options.merge!(src: "/avatar.png")
    render_inline(component)
    assert_selector(".avatar .rounded-full.aspect-square")
  end

  def test_shapes_renders_square_shape
    @options.merge!(src: "/avatar.png", shape: :square)
    render_inline(component)
    assert_selector(".avatar .rounded")
  end

  def test_shapes_renders_rounded_shape
    @options.merge!(src: "/avatar.png", shape: :rounded)
    render_inline(component)
    assert_selector(".avatar .rounded-xl")
  end

  {
    heart: "mask-heart",
    squircle: "mask-squircle",
    hexagon: "mask-hexagon-2",
    triangle: "mask-triangle",
    diamond: "mask-diamond",
    pentagon: "mask-pentagon",
    star: "mask-star"
  }.each do |mask, expected_class|
    define_method("test_masks_renders_#{mask}_mask") do
      render_inline(Bali::Avatar::Component.new(src: "/avatar.png", mask: mask))
      assert_selector(".avatar .mask.#{expected_class}")
    end

    define_method("test_does_not_add_aspect_square_when_#{mask}_mask_is_applied") do
      render_inline(Bali::Avatar::Component.new(src: "/avatar.png", mask: mask))
      assert_no_selector(".aspect-square")
    end
  end

  {
    xs: "w-8",
    sm: "w-12",
    md: "w-16",
    lg: "w-24",
    xl: "w-32"
  }.each do |size, expected_class|
    define_method("test_sizes_renders_size_#{size}_with_#{expected_class}") do
      render_inline(Bali::Avatar::Component.new(src: "/default.png", size: size))
      assert_selector(".avatar .#{expected_class}")
    end
  end

  def test_placeholder_renders_placeholder_with_initials
    render_inline(Bali::Avatar::Component.new(size: :lg, shape: :circle)) do |c|
      c.with_placeholder { "JD" }
    end
    assert_selector(".avatar.avatar-placeholder")
    assert_selector(".bg-neutral.text-neutral-content")
    assert_text("JD")
  end

  def test_placeholder_applies_correct_text_size_for_placeholder
    render_inline(Bali::Avatar::Component.new(size: :xl, shape: :circle)) do |c|
      c.with_placeholder { "AB" }
    end
    assert_selector(".text-3xl")
  end

  def test_placeholder_does_not_show_placeholder_when_src_is_provided
    render_inline(Bali::Avatar::Component.new(src: "/avatar.png", size: :lg)) do |c|
      c.with_placeholder { "JD" }
    end
    assert_no_selector(".avatar-placeholder")
    assert_selector('img[src*="avatar.png"]')
  end

  def test_presence_indicator_renders_online_status
    render_inline(Bali::Avatar::Component.new(src: "/default.png", status: :online))
    assert_selector(".avatar.avatar-online")
  end

  def test_presence_indicator_renders_offline_status
    render_inline(Bali::Avatar::Component.new(src: "/default.png", status: :offline))
    assert_selector(".avatar.avatar-offline")
  end

  def test_ring_styling_renders_with_primary_ring
    render_inline(Bali::Avatar::Component.new(src: "/default.png", ring: :primary))
    assert_selector(".ring-2.ring-primary.ring-offset-2")
  end

  def test_ring_styling_renders_with_success_ring
    render_inline(Bali::Avatar::Component.new(src: "/default.png", ring: :success))
    assert_selector(".ring-2.ring-success")
  end

  def test_ring_styling_renders_without_ring_when_not_specified
    render_inline(Bali::Avatar::Component.new(src: "/default.png"))
    assert_no_selector(".ring-2")
  end

  def test_combined_features_renders_with_size_shape_ring_and_status_together
    render_inline(Bali::Avatar::Component.new(
      src: "/default.png", size: :lg, shape: :circle, ring: :primary, status: :online
    ))
    assert_selector(".avatar.avatar-online")
    assert_selector(".w-24.rounded-full.ring-2.ring-primary")
  end

  def test_options_passthrough_passes_extra_options_to_container
    render_inline(Bali::Avatar::Component.new(src: "/avatar.png", data: { test: "value" }, id: "my-avatar"))
    assert_selector('.avatar[data-test="value"][id="my-avatar"]')
  end

  def test_accessibility_uses_alt_text_when_provided
    render_inline(Bali::Avatar::Component.new(src: "/avatar.png", alt: "User profile picture"))
    assert_selector('img[alt="User profile picture"]')
  end

  def test_accessibility_uses_empty_alt_by_default_for_decorative_images
    render_inline(Bali::Avatar::Component.new(src: "/avatar.png"))
    assert_selector('img[alt=""]')
  end
end

class BaliAvatarUploadComponentTest < ComponentTestCase
  def setup
    @helper = FormHelperTest.new(nil)
  end

  def test_upload_functionality_renders_with_upload_button_overlay
    @helper.form_with(url: "/") do |form|
      render_inline(Bali::Avatar::Upload::Component.new(form: form, method: :avatar, src: "/default-avatar.png"))
    end
    assert_selector('[data-controller="avatar"]')
    assert_selector('label[aria-label="Upload avatar image"]')
    assert_selector('input[type="file"]')
  end

  def test_upload_functionality_wraps_the_avatar_component
    @helper.form_with(url: "/") do |form|
      render_inline(Bali::Avatar::Upload::Component.new(form: form, method: :avatar, src: "/avatar.png", size: :xl))
    end
    assert_selector(".avatar .w-32")
  end

  def test_upload_functionality_renders_camera_icon
    @helper.form_with(url: "/") do |form|
      render_inline(Bali::Avatar::Upload::Component.new(form: form, method: :avatar, src: "/avatar.png"))
    end
    # Check for the icon component being rendered
    assert_selector("label svg", visible: :all)
  end

  def test_upload_functionality_accepts_custom_formats
    @helper.form_with(url: "/") do |form|
      render_inline(Bali::Avatar::Upload::Component.new(form: form, method: :avatar, formats: %w[gif png]))
    end
    assert_selector('input[type="file"][accept=".gif, .png"]')
  end

  def test_upload_functionality_uses_default_formats_when_not_specified
    @helper.form_with(url: "/") do |form|
      render_inline(Bali::Avatar::Upload::Component.new(form: form, method: :avatar))
    end
    assert_selector('input[type="file"][accept=".jpg, .jpeg, .png, .webp"]')
  end

  def test_upload_functionality_passes_size_and_shape_to_avatar
    @helper.form_with(url: "/") do |form|
      render_inline(Bali::Avatar::Upload::Component.new(form: form, method: :avatar, size: :lg, shape: :rounded))
    end
    assert_selector(".avatar .w-24.rounded-xl")
  end

  def test_upload_functionality_adds_stimulus_data_attributes
    @helper.form_with(url: "/") do |form|
      render_inline(Bali::Avatar::Upload::Component.new(form: form, method: :avatar, src: "/avatar.png"))
    end
    assert_selector('[data-controller="avatar"]')
    assert_selector('img[data-avatar-target="output"]')
    assert_selector('input[data-avatar-target="input"]')
    assert_selector('input[data-action="change->avatar#showImage"]')
  end

  def test_upload_functionality_renders_output_target_even_without_src_for_stimulus_controller
    @helper.form_with(url: "/") do |form|
      render_inline(Bali::Avatar::Upload::Component.new(form: form, method: :avatar))
    end
    assert_selector('img[data-avatar-target="output"]')
  end
end

class BaliAvatarGroupComponentTest < ComponentTestCase
  def test_basic_rendering_renders_avatar_group_container
    render_inline(Bali::Avatar::Group::Component.new) do |group|
      group.with_avatar(src: "/avatar1.png", size: :sm)
      group.with_avatar(src: "/avatar2.png", size: :sm)
    end
    assert_selector(".avatar-group.-space-x-6")
    assert_selector(".avatar", count: 2)
  end

  def test_spacing_renders_tight_spacing
    render_inline(Bali::Avatar::Group::Component.new(spacing: :tight)) do |group|
      group.with_avatar(src: "/avatar.png", size: :sm)
    end
    assert_selector(".avatar-group.-space-x-4")
  end

  def test_spacing_renders_normal_spacing_by_default
    render_inline(Bali::Avatar::Group::Component.new) do |group|
      group.with_avatar(src: "/avatar.png", size: :sm)
    end
    assert_selector(".avatar-group.-space-x-6")
  end

  def test_spacing_renders_loose_spacing
    render_inline(Bali::Avatar::Group::Component.new(spacing: :loose)) do |group|
      group.with_avatar(src: "/avatar.png", size: :sm)
    end
    assert_selector(".avatar-group.-space-x-8")
  end

  def test_with_counter_renders_counter_at_the_end
    render_inline(Bali::Avatar::Group::Component.new) do |group|
      group.with_avatar(src: "/avatar.png", size: :sm)
      group.with_avatar(src: "/avatar.png", size: :sm)
      group.with_counter { "+99" }
    end
    assert_selector(".avatar-group .avatar-placeholder")
    assert_text("+99")
  end

  def test_with_counter_uses_group_size_for_counter
    render_inline(Bali::Avatar::Group::Component.new(size: :lg)) do |group|
      group.with_avatar(src: "/avatar.png", size: :lg)
      group.with_counter { "+5" }
    end
    assert_selector(".avatar-placeholder .w-24")
  end

  def test_size_inheritance_avatars_inherit_size_from_group_by_default
    render_inline(Bali::Avatar::Group::Component.new(size: :lg)) do |group|
      group.with_avatar(src: "/avatar.png")
    end
    assert_selector(".avatar .w-24")
  end

  def test_size_inheritance_avatars_can_override_inherited_size
    render_inline(Bali::Avatar::Group::Component.new(size: :lg)) do |group|
      group.with_avatar(src: "/avatar.png", size: :xs)
    end
    assert_selector(".avatar .w-8")
    assert_no_selector(".avatar .w-24")
  end

  def test_options_passthrough_passes_extra_options_to_container
    render_inline(Bali::Avatar::Group::Component.new(data: { testid: "avatar-group" }, id: "my-group")) do |group|
      group.with_avatar(src: "/avatar.png", size: :sm)
    end
    assert_selector('.avatar-group[data-testid="avatar-group"][id="my-group"]')
  end
end

class BaliAvatarPictureComponentTest < ComponentTestCase
  def test_renders_image_with_object_cover_class
    render_inline(Bali::Avatar::Picture::Component.new(image_url: "/avatar.png"))
    assert_selector('img.object-cover[src*="avatar.png"]')
  end

  def test_accepts_additional_options
    render_inline(Bali::Avatar::Picture::Component.new(image_url: "/avatar.png", alt: "User avatar", class: "custom"))
    assert_selector('img[alt="User avatar"]')
    assert_selector("img.custom")
  end

  def test_does_not_add_avatar_target_data_attribute_by_default
    render_inline(Bali::Avatar::Picture::Component.new(image_url: "/avatar.png"))
    assert_no_selector("img[data-avatar-target]")
  end

  def test_accepts_data_attributes_when_passed
    render_inline(Bali::Avatar::Picture::Component.new(image_url: "/avatar.png", data: { avatar_target: "output" }))
    assert_selector('img[data-avatar-target="output"]')
  end
end
