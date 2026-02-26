# frozen_string_literal: true

require "test_helper"

class Bali_Skeleton_ComponentTest < ComponentTestCase
  #

  def test_basic_rendering_renders_text_variant_by_default
    render_inline(Bali::Skeleton::Component.new)
    assert_selector(".skeleton")
  end
  def test_basic_rendering_renders_paragraph_variant
    render_inline(Bali::Skeleton::Component.new(variant: :paragraph, lines: 3))
    assert_selector(".skeleton", count: 3)
  end
  def test_basic_rendering_renders_card_variant
    render_inline(Bali::Skeleton::Component.new(variant: :card))
    assert_selector(".skeleton")
  end
  def test_basic_rendering_renders_avatar_variant
    render_inline(Bali::Skeleton::Component.new(variant: :avatar))
    assert_selector(".skeleton.rounded-full")
  end
  def test_basic_rendering_renders_button_variant
    render_inline(Bali::Skeleton::Component.new(variant: :button))
    assert_selector(".skeleton")
  end
  def test_basic_rendering_renders_modal_variant
    render_inline(Bali::Skeleton::Component.new(variant: :modal))
    assert_selector(".skeleton", minimum: 3)
  end
  def test_basic_rendering_renders_list_variant
    render_inline(Bali::Skeleton::Component.new(variant: :list, lines: 4))
    assert_selector(".skeleton", minimum: 4)
  end
  #

  def test_sizes_renders_xs_size_for_avatar
    render_inline(Bali::Skeleton::Component.new(variant: :avatar, size: :xs))
    assert_selector(".skeleton.w-8.h-8")
  end
  def test_sizes_renders_sm_size_for_avatar
    render_inline(Bali::Skeleton::Component.new(variant: :avatar, size: :sm))
    assert_selector(".skeleton.w-10.h-10")
  end
  def test_sizes_renders_md_size_for_avatar
    render_inline(Bali::Skeleton::Component.new(variant: :avatar, size: :md))
    assert_selector(".skeleton.w-12.h-12")
  end
  def test_sizes_renders_lg_size_for_avatar
    render_inline(Bali::Skeleton::Component.new(variant: :avatar, size: :lg))
    assert_selector(".skeleton.w-16.h-16")
  end
  #

  def test_custom_options_accepts_custom_classes
    render_inline(Bali::Skeleton::Component.new(class: "my-custom-class"))
    assert_selector(".skeleton.my-custom-class")
  end
end
