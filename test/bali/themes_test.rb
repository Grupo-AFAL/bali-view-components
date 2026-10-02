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

  # cypress/support/themes.js lists the same themes for the contrast guards.
  def test_the_expected_themes_ship_with_the_gem
    assert_equal(%w[afal-dark.css afal.css costa-norte-dark.css costa-norte.css],
                 theme_files.map { |file| File.basename(file) })
  end

  def test_every_shipped_theme_is_complete
    theme_files.each do |file|
      css = File.read(file)
      name = File.basename(file, ".css")

      assert_match(/^\[data-theme="#{Regexp.escape(name)}"\]\s*\{/, css,
                   "#{name}.css does not open with [data-theme=\"#{name}\"]")
      assert_match(/color-scheme:\s*(light|dark);/, css,
                   "#{name}.css declares no color-scheme")

      REQUIRED_VARIABLES.each do |variable|
        assert_match(/#{Regexp.escape(variable)}:\s*[^;]+;/, css,
                     "#{name}.css does not define #{variable}")
      end
    end
  end

  # The brand values every host importing afal.css paints: one does not change without an
  # announced visual change (#718, #1221).
  def test_the_afal_brand_values_stay_canonical
    css = File.read(THEMES_DIR.join("afal.css"))

    assert_includes(css, "--color-primary: oklch(54.6% 0.245 262.881)")
    assert_includes(css, "--color-secondary: oklch(60.56% 0.2189 292.717)")
    assert_includes(css, "--color-accent: oklch(76.86% 0.1647 70.080)")
    assert_includes(css, "--radius-field: 0.375rem")
    assert_includes(css, "color-scheme: light")
  end

  # daisyUI's order, dark themes included: hosts lay base-100 cards on a base-200 page, and a
  # dark theme that stepped up instead painted the page lighter than its cards.
  def test_every_theme_steps_its_surfaces_down_from_base_100
    theme_files.each do |file|
      css = File.read(file)
      levels = %w[100 200 300].map { |step| lightness(css, "--color-base-#{step}", file) }

      assert levels.each_cons(2).all? { |upper, lower| upper > lower },
             "#{File.basename(file)}: base-100/200/300 lightness #{levels.join(' / ')}"
    end
  end

  def test_the_dark_themes_declare_a_dark_scheme
    %w[afal-dark costa-norte-dark].each do |name|
      assert_includes(File.read(THEMES_DIR.join("#{name}.css")), "color-scheme: dark", name)
    end
  end

  private

  # The L of an `oklch()` token, written either as a percentage or as a fraction.
  def lightness(css, variable, file)
    pattern = /#{Regexp.escape(variable)}:\s*oklch\(([\d.]+)(%?)/
    assert_match pattern, css, "#{File.basename(file)}: #{variable} is not an oklch() colour"
    number, percent = css.match(pattern).captures
    percent.empty? ? number.to_f : number.to_f / 100
  end
end
