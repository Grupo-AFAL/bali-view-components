# frozen_string_literal: true

require "test_helper"

# A half-finished theme does not fail: the missing variable is inherited from whichever theme came
# before it in the cascade, and the bug shows up as "an odd colour" months later. This test reads
# every file in app/assets/stylesheets/bali/themes/ and demands the full set of variables
# docs/guides/custom-themes.md documents, plus `color-scheme` and that the [data-theme] selector
# match the file's name (a typo there publishes a theme nobody can activate).
class BaliThemesTest < ActiveSupport::TestCase
  THEMES_DIR = Bali::Engine.root.join("app/assets/stylesheets/bali/themes")

  REQUIRED_VARIABLES = %w[
    --color-base-100 --color-base-200 --color-base-300 --color-base-content
    --color-primary --color-primary-content
    --color-secondary --color-secondary-content
    --color-accent --color-accent-content
    --color-neutral --color-neutral-content
    --color-info --color-info-content
    --color-success --color-success-content
    --color-warning --color-warning-content
    --color-error --color-error-content
    --radius-selector --radius-field --radius-box
    --size-selector --size-field
    --border --depth --noise
  ].freeze

  def theme_files
    Dir[THEMES_DIR.join("*.css").to_s].sort
  end

  def test_the_expected_themes_ship_with_the_gem
    assert_equal(%w[afal-dark.css afal.css costa-norte.css],
                 theme_files.map { |file| File.basename(file) })
  end

  def test_every_shipped_theme_is_complete
    theme_files.each do |file|
      css = File.read(file)
      name = File.basename(file, ".css")

      assert_match(/^\[data-theme="#{Regexp.escape(name)}"\]\s*\{/, css,
                   "#{name}.css no define [data-theme=\"#{name}\"] al inicio de línea")
      assert_match(/color-scheme:\s*(light|dark);/, css,
                   "#{name}.css no declara color-scheme")

      REQUIRED_VARIABLES.each do |variable|
        assert_match(/#{Regexp.escape(variable)}:\s*[^;]+;/, css,
                     "#{name}.css no define #{variable}")
      end
    end
  end

  # afal.css's block is the canonical copy of the one the apps used to carry by hand (#718): the
  # brand values do not change without being an announced visual change.
  def test_the_afal_brand_values_stay_canonical
    css = File.read(THEMES_DIR.join("afal.css"))

    assert_includes(css, "--color-primary: oklch(62.31% 0.1880 259.815)")
    assert_includes(css, "--color-secondary: oklch(60.56% 0.2189 292.717)")
    assert_includes(css, "--color-accent: oklch(76.86% 0.1647 70.080)")
    assert_includes(css, "--radius-field: 0.375rem")
    assert_includes(css, "color-scheme: light")
  end

  def test_the_afal_dark_draft_declares_a_dark_scheme
    css = File.read(THEMES_DIR.join("afal-dark.css"))

    assert_includes(css, "color-scheme: dark")
    assert_match(/DRAFT/, css, "afal-dark.css debe declararse borrador hasta su aprobación visual")
  end
end
