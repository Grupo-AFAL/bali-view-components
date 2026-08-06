# frozen_string_literal: true

require "test_helper"

class BaliQrCodeComponentTest < ComponentTestCase
  PAYLOAD = "https://github.com/Grupo-AFAL/bali"

  def test_renders_an_svg_with_the_component_class
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD))
    assert_selector("svg.qr-code-component")
  end

  def test_renders_the_modules_as_a_single_path
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD))
    assert_selector("svg path")
  end

  # Two payloads that encode differently have to render differently, or the
  # component is drawing something other than what it was given.
  def test_encodes_the_payload
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD))
    first = rendered_content

    render_inline(Bali::QrCode::Component.new(payload: "something else"))

    refute_equal first, rendered_content
  end

  def test_payload_is_required
    error = assert_raises(ArgumentError) { Bali::QrCode::Component.new(payload: "") }
    assert_match(/payload is required/, error.message)
  end

  # A code flush against its neighbours is a code some scanners never find, so
  # the four-module quiet zone is part of the viewBox rather than something the
  # host is expected to add with padding.
  def test_viewbox_includes_the_quiet_zone_on_both_sides
    component = Bali::QrCode::Component.new(payload: PAYLOAD)
    render_inline(component)

    modules = RQRCode::QRCode.new(PAYLOAD, level: :m).modules.size
    extent = modules + (2 * Bali::QrCode::Component::QUIET_ZONE_MODULES)

    assert_includes rendered_content, %(viewBox="0 0 #{extent} #{extent}")
  end

  # Dark-on-light is what a scanner reads. Without an opaque white plate the
  # code inherits whatever surface it lands on, and stops scanning under a dark
  # theme — while still looking like a QR code.
  def test_paints_an_opaque_white_background_behind_the_modules
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD))
    assert_includes rendered_content, %(fill="#fff")
    assert_includes rendered_content, %(fill="#000")
  end

  def test_size_sets_the_rendered_dimensions
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD, size: 320))
    assert_selector('svg[width="320"][height="320"]')
  end

  def test_size_defaults_to_200
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD))
    assert_selector('svg[width="200"][height="200"]')
  end

  # The viewBox is what makes the width/height attributes a default rather than
  # a cage: a host class scales the code without touching the component.
  def test_size_can_be_overridden_by_a_class
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD, class: "w-full h-auto"))
    assert_selector("svg.qr-code-component.w-full")
  end

  def test_level_changes_the_generated_code
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD, level: :l))
    lightest = rendered_content

    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD, level: :h))

    refute_equal lightest, rendered_content
  end

  def test_level_accepts_every_documented_value
    Bali::QrCode::Component::LEVELS.each do |level|
      render_inline(Bali::QrCode::Component.new(payload: PAYLOAD, level: level))
      assert_selector("svg.qr-code-component")
    end
  end

  def test_unknown_level_raises_with_the_valid_ones
    error = assert_raises(ArgumentError) do
      Bali::QrCode::Component.new(payload: PAYLOAD, level: :x)
    end

    assert_match(/unknown level :x/, error.message)
    assert_match(/:l, :m, :q, :h/, error.message)
  end

  def test_a11y_exposes_the_code_as_an_image
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD))
    assert_selector('svg[role="img"]')
  end

  def test_a11y_names_the_code_by_default
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD))
    assert_selector('svg[aria-label="QR code"]')
  end

  def test_a11y_accepts_a_label_for_context
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD, label: "Scan to check in"))
    assert_selector('svg[aria-label="Scan to check in"]')
  end

  def test_a11y_translates_the_default_name
    I18n.with_locale(:es) do
      render_inline(Bali::QrCode::Component.new(payload: PAYLOAD))
      assert_selector('svg[aria-label="Código QR"]')
    end
  end

  def test_options_passthrough_merges_custom_classes
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD, class: "custom-class"))
    assert_selector("svg.qr-code-component.custom-class")
  end

  def test_options_passthrough_passes_data_attributes
    render_inline(Bali::QrCode::Component.new(payload: PAYLOAD, data: { testid: "qr" }))
    assert_selector('[data-testid="qr"]')
  end

  # rqrcode is not in the gemspec on purpose, so the failure a host actually
  # meets is a missing gem at render time. It has to name the line to add: a
  # bare `cannot load such file -- rqrcode` from inside a view component says
  # nothing about which Gemfile or which version.
  def test_missing_rqrcode_raises_with_installation_instructions
    component = Bali::QrCode::Component.new(payload: PAYLOAD)
    # The gem is installed here, so an unloadable `require` is the only way to
    # reach the path a host without it takes.
    component.define_singleton_method(:require) { |_name| raise LoadError }

    error = assert_raises(Bali::QrCode::Component::MissingDependency) do
      render_inline(component)
    end

    assert_match(/rqrcode/, error.message)
    assert_match(/Gemfile/, error.message)
    assert_match(/bundle install/, error.message)
  end

  # ...and it stays a LoadError, so a host that wants to degrade instead of
  # blowing up can rescue the ordinary thing.
  def test_missing_rqrcode_is_still_a_load_error
    assert_operator Bali::QrCode::Component::MissingDependency, :<, LoadError
  end
end
