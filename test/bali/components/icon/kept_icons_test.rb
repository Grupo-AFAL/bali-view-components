# frozen_string_literal: true

require "test_helper"

class BaliIconKeptIconsTest < ActiveSupport::TestCase
  #

  def test_exists_returns_true_for_brand_payment_icons
    assert(Bali::Icon::KeptIcons.exists?("visa"))
    assert(Bali::Icon::KeptIcons.exists?("mastercard"))
    assert(Bali::Icon::KeptIcons.exists?("american-express"))
  end

  def test_exists_returns_true_for_brand_social_icons
    assert(Bali::Icon::KeptIcons.exists?("whatsapp"))
    assert(Bali::Icon::KeptIcons.exists?("facebook"))
    assert(Bali::Icon::KeptIcons.exists?("youtube"))
  end

  def test_exists_returns_true_for_regional_icons
    assert(Bali::Icon::KeptIcons.exists?("mexico-flag"))
    assert(Bali::Icon::KeptIcons.exists?("us-flag"))
  end

  def test_exists_returns_true_for_custom_domain_icons
    assert(Bali::Icon::KeptIcons.exists?("recipe-book"))
    assert(Bali::Icon::KeptIcons.exists?("diagnose"))
  end

  def test_exists_returns_false_for_icons_not_in_kept_set
    refute(Bali::Icon::KeptIcons.exists?("user"))
    refute(Bali::Icon::KeptIcons.exists?("edit"))
  end

  def test_exists_accepts_symbols
    assert(Bali::Icon::KeptIcons.exists?(:visa))
  end
  #

  def test_find_returns_svg_markup_for_kept_icons
    svg = Bali::Icon::KeptIcons.find("visa")
    assert_includes(svg, "<svg")
    assert_includes(svg, "</svg>")
  end

  def test_find_raises_error_for_non_kept_icons
    assert_raises(Bali::Icon::Options::IconNotAvailable) do
      Bali::Icon::KeptIcons.find("user")
    end
  end


  #

  def test_find_brand_returns_true_for_brand_icons
    assert(Bali::Icon::KeptIcons.brand?("visa"))
    assert(Bali::Icon::KeptIcons.brand?("whatsapp"))
  end

  def test_find_brand_returns_false_for_non_brand_icons
    refute(Bali::Icon::KeptIcons.brand?("mexico-flag"))
    refute(Bali::Icon::KeptIcons.brand?("recipe-book"))
  end
  #

  def test_find_regional_returns_true_for_regional_icons
    assert(Bali::Icon::KeptIcons.regional?("mexico-flag"))
    assert(Bali::Icon::KeptIcons.regional?("us-flag"))
  end

  def test_find_regional_returns_false_for_non_regional_icons
    refute(Bali::Icon::KeptIcons.regional?("visa"))
  end
  #

  def test_find_custom_returns_true_for_custom_domain_icons
    assert(Bali::Icon::KeptIcons.custom?("recipe-book"))
    assert(Bali::Icon::KeptIcons.custom?("diagnose"))
  end

  def test_find_custom_returns_false_for_non_custom_icons
    refute(Bali::Icon::KeptIcons.custom?("visa"))
  end
  #

  def test_find_constants_has_frozen_brand_payment
    assert(Bali::Icon::KeptIcons::BRAND_PAYMENT.frozen?)
  end

  def test_find_constants_has_frozen_brand_social
    assert(Bali::Icon::KeptIcons::BRAND_SOCIAL.frozen?)
  end

  def test_find_constants_has_frozen_regional
    assert(Bali::Icon::KeptIcons::REGIONAL.frozen?)
  end

  def test_find_constants_has_frozen_custom
    assert(Bali::Icon::KeptIcons::CUSTOM.frozen?)
  end

  def test_find_constants_has_frozen_all_containing_all_categories
    assert(Bali::Icon::KeptIcons::ALL.frozen?)
    Bali::Icon::KeptIcons::BRAND_PAYMENT.each { |icon| assert_includes(Bali::Icon::KeptIcons::ALL, icon) }
    Bali::Icon::KeptIcons::BRAND_SOCIAL.each { |icon| assert_includes(Bali::Icon::KeptIcons::ALL, icon) }
    Bali::Icon::KeptIcons::REGIONAL.each { |icon| assert_includes(Bali::Icon::KeptIcons::ALL, icon) }
    Bali::Icon::KeptIcons::CUSTOM.each { |icon| assert_includes(Bali::Icon::KeptIcons::ALL, icon) }
  end
end
