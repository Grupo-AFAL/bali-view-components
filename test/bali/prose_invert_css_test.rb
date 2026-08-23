# frozen_string_literal: true

require "test_helper"

# daisyUI maps Tailwind Typography onto the theme with `:root .prose` at
# specificity (0,2,0), which outranks the plugin's own `.prose-invert` (0,1,0)
# by construction — so Bali ships bali/prose-invert.css to restore the class
# (#1063). This keeps that sheet honest against the daisyUI the dummy actually
# installs: every `--tw-prose-*` variable daisyUI's mapping sets must be
# re-pointed at its `--tw-prose-invert-*` counterpart, or a future daisyUI
# addition would silently reintroduce dark-on-dark for that piece of prose.
class BaliProseInvertCssTest < ActiveSupport::TestCase
  ENGINE_SHEET = Bali::Engine.root.join("app/assets/stylesheets/bali/prose-invert.css")
  DAISYUI_TYPOGRAPHY = Bali::Engine.root.join(
    "spec/dummy/node_modules/daisyui/utilities/typography.css"
  )

  def test_every_variable_daisyui_maps_has_an_invert_mapping
    skip("daisyUI not installed (yarn install in spec/dummy)") unless DAISYUI_TYPOGRAPHY.exist?

    daisyui_vars = daisyui_prose_variables
    assert_includes(daisyui_vars, "--tw-prose-body") # sanity: the parse found the mapping

    sheet = ENGINE_SHEET.read
    daisyui_vars.each do |var|
      invert = var.sub("--tw-prose-", "--tw-prose-invert-")
      assert_includes(
        sheet, "#{var}: var(#{invert})",
        "daisyUI's `:root .prose` sets #{var}, but bali/prose-invert.css does not restore it"
      )
    end
  end

  # `.prose-invert` alone would lose the fight this sheet exists to win: it
  # must carry `:root` to reach (0,2,0), and stay unlayered (bali.css keeps it
  # in the unlayered group) to outrank daisyUI's utilities layer.
  def test_the_selector_matches_daisyuis_specificity
    assert_includes(ENGINE_SHEET.read, ":root .prose-invert")
  end

  # The other load-bearing cascade fact: the sheet must stay UNLAYERED. An
  # import-cleanup that adds `layer(components)` — the pattern of nearly every
  # neighboring line in bali.css — would kill the fix outright (components
  # loses to daisyUI's utilities layer regardless of specificity) while every
  # content assertion above stayed green.
  def test_bali_css_imports_the_sheet_unlayered
    entry = Bali::Engine.root.join("app/assets/stylesheets/bali.css").read
    import_line = entry.lines.find { |l| l.include?("prose-invert.css") }

    assert(import_line, "bali.css no longer imports bali/prose-invert.css")
    refute_match(/layer\(/, import_line, "prose-invert.css must stay unlayered — see its header")
  end

  # daisyUI's mapping has a second half: an inline-code chip painted
  # `background-color: base-200` with no `color`. Re-pointing the variables
  # alone leaves inverted code text near-white on that near-white chip, so the
  # sheet must also carry the chip counter-rule at daisyUI's own specificity.
  def test_the_inline_code_chip_is_countered
    assert_includes(ENGINE_SHEET.read, ":root .prose-invert :where(code):not(pre > code)")
  end

  private

  # The `--tw-prose-*` custom properties daisyUI's `:root .prose` rule
  # declares (stopping before the nested `& :where(code)` block, which sets no
  # prose variables).
  def daisyui_prose_variables
    css = DAISYUI_TYPOGRAPHY.read
    mapping = css[/:root \.prose\{[^&]*/]
    flunk("could not find `:root .prose` in daisyUI's typography.css") if mapping.nil?

    mapping.scan(/(--tw-prose-[a-z-]+):/).flatten.uniq
  end
end
