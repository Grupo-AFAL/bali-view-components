# frozen_string_literal: true

require "test_helper"
require "prawn"
require "prawn-svg"

# The editor's `bali-bpmn:export` SVG drawn into a PDF the way a host does it,
# with prawn-svg. The fixture is the "before" side of the compare_flows
# preview exported with `frame: false` (marks, a removed lane, labels); the
# Cypress spec bpmn-export.cy.js checks the live export keeps its shape.
class BaliBpmnEditorPrawnSvgExportTest < ActiveSupport::TestCase
  FIXTURE = Bali::Engine.root.join("test/fixtures/bpmn_editor/export_frameless.svg")
  COLOR_ATTRIBUTE = /\s(?:fill|stroke)="([^"]+)"|(?:fill|stroke):\s*([^;"]+)/

  setup { Prawn::Fonts::AFM.hide_m17n_warning = true }

  def render(svg, &)
    pdf = Prawn::Document.new(page_size: "LETTER", page_layout: :landscape, compress: false)
    yield pdf if block_given?
    result = pdf.svg(svg, width: pdf.bounds.width, enable_web_requests: false)
    [ result, pdf.render ]
  end

  def test_prawn_svg_draws_it_without_warnings
    result, = render(FIXTURE.read)

    assert_empty result[:warnings]
  end

  # prawn-svg reads hex, rgb() and names; an oklch() it cannot read is painted
  # black, which is what the island's computed daisyUI colours used to give.
  def test_every_colour_reaches_the_pdf_as_it_is_in_the_svg
    svg = FIXTURE.read
    _, pdf = render(svg)
    painted = pdf.scan(/^([\d.]+ [\d.]+ [\d.]+) (?:scn|SCN)$/).flatten.to_set
    colours = svg.scan(COLOR_ATTRIBUTE).flatten.compact.map(&:strip).uniq - %w[none]

    assert_operator colours.size, :>, 5
    colours.each do |colour|
      channels = channels_of(colour) or flunk "prawn-svg does not read #{colour}"
      assert_includes painted, channels.map { |c| (c / 255.0).round(5).to_s }.join(" "), "#{colour} is not painted"
    end
  end

  # The two spellings the export writes: hex in attributes, rgb() where the
  # browser serialised a style.
  def channels_of(colour)
    if colour.match?(/\A#\h{6}\z/) then colour.delete("#").scan(/\h\h/).map(&:hex)
    elsif (rgb = colour.match(/\Argb\((\d+), (\d+), (\d+)\)\z/)) then rgb.captures.map(&:to_i)
    end
  end

  # The family the SVG declares is the host's to map onto an embedded font.
  def test_a_host_maps_the_declared_font_family_onto_its_own_font
    _, pdf = render(FIXTURE.read) do |document|
      document.font_families.update("system-ui" => { normal: "Courier", bold: "Courier-Bold" })
    end

    assert_includes pdf, "/BaseFont /Courier"
    assert_not_includes pdf, "/BaseFont /Helvetica"
  end
end
