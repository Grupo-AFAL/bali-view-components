# frozen_string_literal: true

require "test_helper"

# Lists Ruby validates and the island reads: each one is written on both
# sides, each side naming the other, and this test keeps them equal. It reads
# the JavaScript source, so a constant renamed there fails here.
class BaliBpmnEditorContractTest < ActiveSupport::TestCase
  ROOT = Bali::Engine.root.join("app/components/bali/bpmn_editor")

  def js_list(file, constant)
    source = ROOT.join(file).read
    body = source[/export const #{constant} = \[([^\]]*)\]/m, 1] or flunk "#{constant} not found in #{file}"
    body.scan(/'([^']+)'/).flatten
  end

  # Component#i18n_table_tag writes the strings table once per render;
  # islandStrings (i18n.js) finds it by the same attribute, and index.js reads
  # the key the editors carry.
  def test_the_strings_table_is_found_by_the_attribute_ruby_writes
    html = ApplicationController.render(Bali::BpmnEditor::Component.new(data: {}), layout: false)
    attribute = html[/<script type="application\/json" (data-[\w-]+)="\h{16}"/, 1] or flunk "no strings table in #{html[0, 200]}"

    assert_includes ROOT.join("i18n.js").read, %([#{attribute}="${key}"])
    assert_match(/data-bpmn-editor-i18n-key-value="\h{16}"/, html)
    assert_match(/^\s+i18nKey: \{ type: String/, ROOT.join("index.js").read)
    assert_includes ROOT.join("i18n.js").read, %(I18N_TABLES_HEADER = '#{Bali::BpmnEditor::Component::I18N_TABLES_HEADER}')
  end

  def test_edge_types
    assert_equal Bali::BpmnEditor::Data::EDGE_TYPES, js_list("model/catalog.js", "EDGE_TYPES")
  end

  def test_field_types
    assert_equal Bali::BpmnEditor::Component::FIELD_TYPES, js_list("chrome/PropertiesPanel.jsx", "FIELD_TYPES")
  end

  def test_legend_swatches
    assert_equal Bali::BpmnEditor::Component::LEGEND_SWATCHES, js_list("chrome/Legend.jsx", "LEGEND_SWATCHES")
  end

  def test_layouts
    assert_equal Bali::BpmnEditor::Component::LAYOUTS.map(&:to_s), js_list("model/layout.js", "LAYOUTS")
  end

  def test_the_default_page_is_the_islands_letter
    letter = ROOT.join("model/page.js").read[/export const LETTER = \{([^}]*)\}/, 1] or flunk "LETTER not found in page.js"
    js = letter.scan(/(\w+): ('[^']*'|[\d.]+)/).to_h { |key, value| [ key.to_sym, value.start_with?("'") ? value.delete("'") : value.to_f ] }

    assert_equal Bali::BpmnEditor::Component::DEFAULT_PAGE.transform_values { |v| v.is_a?(Numeric) ? v.to_f : v }, js
  end

  # The rule options are the keys the rules read through ctx.option / ruleOption.
  def test_rule_options
    read = Dir[ROOT.join("model/**/*.js")].flat_map do |file|
      File.read(file).scan(/(?:\.option\(|ruleOption\(\w+, )'(\w+)'/).flatten
    end

    assert_equal Bali::BpmnEditor::Component::RULE_OPTIONS.map(&:to_s).sort, read.uniq.sort
  end

  def test_compare_matches
    assert_equal Bali::BpmnEditor::Component::COMPARE_MATCHES.map(&:to_s), js_list("model/diff.js", "COMPARE_MATCHES")
  end

  def test_wheel_zooms
    assert_equal Bali::BpmnEditor::Component::WHEEL_ZOOMS, js_list("BpmnEditor.jsx", "WHEEL_ZOOMS")
    assert_match(/wheelZoom: \{ type: String, default: 'auto' \}/, ROOT.join("index.js").read)
  end

  def test_the_badge_toggle_label_has_one_limit
    assert_equal Bali::BpmnEditor::Component::BADGE_TOGGLE_MAX,
                 ROOT.join("chrome/BadgeSwitch.jsx").read[/export const BADGE_TOGGLE_MAX = (\d+)/, 1].to_i
    assert_match(/badgeToggleLabel: \{ type: String, default: '' \}/, ROOT.join("index.js").read)
  end

  def test_chromes
    assert_equal Bali::BpmnEditor::Component::CHROMES.map(&:to_s), js_list("BpmnEditor.jsx", "CHROMES")
  end

  def test_appearance
    source = ROOT.join("model/appearance.js").read

    assert_equal Bali::BpmnEditor::Data::APPEARANCE_KEYS.map(&:to_s), js_list("model/appearance.js", "APPEARANCE_KEYS")
    assert_equal Bali::BpmnEditor::Data::BADGE_MAX, source[/export const BADGE_MAX = (\d+)/, 1].to_i
  end

  def test_the_default_min_zoom_is_the_fits_floor
    floor = ROOT.join("canvas/fit.js").read[/export const MIN_FIT_ZOOM = ([\d.]+)/, 1] or flunk "MIN_FIT_ZOOM not found in fit.js"
    controller = ROOT.join("index.js").read[/minZoom: \{ type: Number, default: ([\d.]+) \}/, 1] or flunk "minZoom not found in index.js"

    assert_equal Bali::BpmnEditor::Component::DEFAULT_MIN_ZOOM, floor.to_f
    assert_equal Bali::BpmnEditor::Component::DEFAULT_MIN_ZOOM, controller.to_f
  end

  # `badges:` and `badge_toggle:` cross only when false (component_test pins
  # that), so the island's own defaults have to be true, as Ruby's are.
  def test_badges_default_to_shown_on_both_sides
    source = ROOT.join("index.js").read
    ruby = Bali::BpmnEditor::Component.instance_method(:initialize).parameters

    assert_match(/badges: \{ type: Boolean, default: true \}/, source)
    assert_match(/badgeToggle: \{ type: Boolean, default: true \}/, source)
    assert_match(/badges = true, badgeToggle = true/, ROOT.join("BpmnEditor.jsx").read)
    assert_includes ruby, [ :key, :badges ]
    assert_includes ruby, [ :key, :badge_toggle ]
  end

  # `rules: false` travels as the `validate` value (a Stimulus Object value
  # reads only objects) and the controller turns it back into `rules: false`.
  def test_rules_false_crosses_as_the_validate_value
    source = ROOT.join("index.js").read

    assert_match(/validate: \{ type: Boolean, default: true \}/, source)
    assert_match(/if \(validate === false\) return false/, source)
    assert_match(/if \(config === false\) return false/, ROOT.join("model/rules/engine.js").read)
  end

  # `rules: :structure` arrives as { profile: "structure" } and the controller
  # hands the island the profile's name, which the engine reads.
  def test_rule_profiles
    assert_equal Bali::BpmnEditor::Component::RULE_PROFILES.map(&:to_s), js_list("model/rules/engine.js", "RULE_PROFILES")
    assert_equal Bali::BpmnEditor::Component::STRUCTURE_PROFILE, js_list("model/rules/engine.js", "STRUCTURE_PROFILE")
    assert_match(/if \(rules && rules\.profile\) return String\(rules\.profile\)/, ROOT.join("index.js").read)
  end
end
