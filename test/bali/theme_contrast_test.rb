# frozen_string_literal: true

require "test_helper"

# Pairs a theme carries on its own, with nothing of a component's between them: a colour under its
# `-content`, a colour as text on base-100, a `text-soft-<colour>` on base-100. Computed from the
# theme files the way Chrome paints them, to an 8-bit pixel, they are the ratios
# cypress/support/painted_contrast.js read off a canvas: afal's primary button 5.25:1 in both,
# afal-dark's text-soft-warning 12.75. Where Chrome's float32 lands a channel on .5 the pixel can
# differ by one step: daisyUI's `dark` text-soft-error reads 10.39 here and 10.45 there.
#
# What a component composes on top — an alpha over the surface it lands on, an `opacity` on a
# parent, a tint under the text, a `data-theme` of its own — only a browser sees, and stays in the
# Cypress guards. That a component paints one of these pairs is its own Minitest's to pin:
# `text-soft-*` in delete_link_test.rb, loader_test.rb, widget_trend_indicator_test.rb,
# split_view_list_test.rb and boolean_icon_test.rb.
class BaliThemeContrastTest < ActiveSupport::TestCase
  AA = 4.5

  BALI_THEMES = Bali::Engine.root.join("app/assets/stylesheets/bali/themes")
  UTILITIES = Bali::Engine.root.join("app/assets/stylesheets/bali/utilities.css")
  DAISYUI_THEMES = Bali::Engine.root.join("test/dummy/node_modules/daisyui/theme")

  SOFT_COLOURS = %w[primary secondary accent info success warning error].freeze

  # `afal` shipped blue-500 under white, 3.68:1 on both, against AA's 4.5 for a button's 14px
  # label (#1221), and violet-500 under white at 4.23 (#1261). daisyUI's own `light` and `dark` are
  # not Bali's to change: `dark` paints its primary button at 4.13:1, and both their secondary at
  # 3.04. The secondary is not text on the page: `costa-norte`'s is a gold fill, 1.99:1 there, and
  # where Bali writes a secondary on the page it paints `text-soft-secondary` (#1281).
  def test_the_primary_and_secondary_of_every_bali_theme_read_at_aa
    below = bali_themes.flat_map do |name, tokens|
      [
        [ "the primary button", tokens["primary-content"], tokens["primary"] ],
        [ "primary text on the page", tokens["primary"], tokens["base-100"] ],
        [ "the secondary button", tokens["secondary-content"], tokens["secondary"] ]
      ].filter_map do |what, ink, ground|
        ratio = contrast(ink, ground)
        "#{name}: #{what} #{ratio.round(2)}:1" if ratio < AA
      end
    end

    assert_empty below
  end

  # `text-soft-<colour>` (app/assets/stylesheets/bali/utilities.css) on a base-100 page or card,
  # where it replaced a `text-<colour>` that missed AA on every light theme: `text-success` read
  # 1.96:1 on `light`, `text-error` 2.75 on `afal`, `text-secondary` 1.99 on `costa-norte` (#1281).
  def test_every_soft_colour_reads_at_aa_on_base_100_in_every_theme
    skip("daisyUI not installed (yarn install in test/dummy)") unless DAISYUI_THEMES.exist?

    below = every_theme.flat_map do |name, tokens|
      SOFT_COLOURS.filter_map do |colour|
        ratio = contrast(soft_ink(tokens, colour), tokens["base-100"])
        "#{name}: text-soft-#{colour} #{ratio.round(2)}:1" if ratio < AA
      end
    end

    assert_empty below
  end

  # The 40% mix with base-content read brown for error on a light theme: rgb(114, 72, 80) on
  # `afal`, chroma 0.05 (#1330). A dark theme keeps that mix, a pale red.
  def test_the_soft_error_of_a_light_theme_paints_red
    skip("daisyUI not installed (yarn install in test/dummy)") unless DAISYUI_THEMES.exist?

    every_theme.each do |name, tokens|
      next unless tokens[:scheme] == "light"

      _, chroma, hue = oklch_of(painted(soft_ink(tokens, "error")))
      assert_operator chroma, :>=, 0.12, "#{name}: text-soft-error chroma"
      assert(hue < 40 || hue > 340, "#{name}: text-soft-error hue #{hue.round} is red")
    end
  end

  private

  def bali_themes
    Dir[BALI_THEMES.join("*.css").to_s].sort.to_h { |file| [ File.basename(file, ".css"), tokens(File.read(file)) ] }
  end

  def every_theme
    %w[light dark].to_h { |name| [ name, tokens(DAISYUI_THEMES.join("#{name}.css").read) ] }.merge(bali_themes)
  end

  # { "primary" => OKLab [l, a, b], …, scheme: "light" | "dark" }
  def tokens(css)
    colours = css.scan(/--color-([\w-]+):\s*oklch\(([\d.]+)(%?)\s+([\d.]+)\s+([\d.]+)\)/)
                 .to_h { |name, l, percent, c, h| [ name, lab_of(l.to_f / (percent.empty? ? 1 : 100), c.to_f, h.to_f) ] }
    colours.merge(scheme: css[/color-scheme:\s*(light|dark)/, 1])
  end

  # The declaration in utilities.css, read from it: base-content tinted toward the colour, and
  # error's own ink on a light scheme, the error token at a lightness of its own.
  def soft_ink(tokens, colour)
    css = UTILITIES.read
    weight = css[/@utility text-soft-\* \{\s*color: color-mix\(in oklab, --value\(--color-\*\) ([\d.]+)%, var\(--color-base-content\)\);/, 1]
    lightness = css[/--soft-ink-error: light-dark\(oklch\(from var\(--color-error\) ([\d.]+) c h\),/, 1]
    refute_nil(weight, "bali/utilities.css no longer writes text-soft-* as a color-mix with base-content")
    refute_nil(lightness, "bali/utilities.css no longer gives error an ink of its own on a light scheme")

    if colour == "error" && tokens[:scheme] == "light"
      _, chroma, hue = oklch_of(tokens["error"])
      return lab_of(lightness.to_f, chroma, hue)
    end

    weight = weight.to_f / 100
    tokens[colour].zip(tokens["base-content"]).map { |ink, base| (weight * ink) + ((1 - weight) * base) }
  end

  # The OKLab of the 8-bit pixel a colour paints, clipped channels and all.
  def painted(lab)
    r, g, b = srgb(lab).map do |v|
      v /= 255.0
      v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end
    l, m, s = [
      (0.4122214708 * r) + (0.5363325363 * g) + (0.0514459929 * b),
      (0.2119034982 * r) + (0.6806995451 * g) + (0.1073969566 * b),
      (0.0883024619 * r) + (0.2817188376 * g) + (0.6299787005 * b)
    ].map { |v| Math.cbrt(v) }
    [
      (0.2104542553 * l) + (0.7936177850 * m) - (0.0040720468 * s),
      (1.9779984951 * l) - (2.4285922050 * m) + (0.4505937099 * s),
      (0.0259040371 * l) + (0.7827717662 * m) - (0.8086757660 * s)
    ]
  end

  def lab_of(lightness, chroma, hue)
    radians = hue * Math::PI / 180
    [ lightness, chroma * Math.cos(radians), chroma * Math.sin(radians) ]
  end

  def oklch_of((lightness, a, b))
    [ lightness, Math.hypot(a, b), ((Math.atan2(b, a) * 180 / Math::PI) + 360) % 360 ]
  end

  # OKLab (Björn Ottosson) to the 8-bit pixel a 1px canvas returns, out-of-gamut channels clipped.
  def srgb((lightness, a, b))
    l = (lightness + (0.3963377774 * a) + (0.2158037573 * b))**3
    m = (lightness - (0.1055613458 * a) - (0.0638541728 * b))**3
    s = (lightness - (0.0894841775 * a) - (1.2914855480 * b))**3
    [
      (4.0767416621 * l) - (3.3077115913 * m) + (0.2309699292 * s),
      (-1.2684380046 * l) + (2.6097574011 * m) - (0.3413193965 * s),
      (-0.0041960863 * l) - (0.7034186147 * m) + (1.7076147010 * s)
    ].map do |v|
      v = v.clamp(0.0, 1.0)
      ((v <= 0.0031308 ? 12.92 * v : (1.055 * (v**(1 / 2.4))) - 0.055) * 255).round
    end
  end

  def contrast(first, second)
    low, high = [ first, second ].map { |lab| luminance(srgb(lab)) }.minmax
    (high + 0.05) / (low + 0.05)
  end

  def luminance(rgb)
    r, g, b = rgb.map do |v|
      v /= 255.0
      v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055)**2.4
    end
    (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
  end
end
