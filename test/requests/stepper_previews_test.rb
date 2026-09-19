# frozen_string_literal: true

require "test_helper"

# Nothing in the suite walks Lookbook's previews — `canonical_previews_test.rb`
# covers four components and `icon_previews_test.rb` only the sibling-constant
# pattern — and stepper has no Cypress spec, so a broken preview file would be
# silent. These pin the five variants and, for `with_content_block`, the claim
# that variant exists to make.
class StepperPreviewsTest < ActionDispatch::IntegrationTest
  BASE = "/lookbook/preview/bali/stepper"

  VARIANTS = %w[default vertical with_sublabels colors with_content_block].freeze

  def test_every_variant_renders
    VARIANTS.each do |variant|
      get "#{BASE}/#{variant}"
      assert_response :ok, "#{variant} no renderizó"
    end
  end

  # What the variant is for: a block that decides inside and writes nothing
  # leaves the step exactly as one declared with no block at all. Lookbook
  # renders it as ERB, which is how a host writes it — so this is the assertion
  # that goes red against `content?`, at the request level and on the artifact
  # the PR added rather than on a hand-rolled fixture.
  def test_the_content_block_variant_renders_both_steppers_the_same
    get "#{BASE}/with_content_block"

    deciding_inside, written_by_hand = css_select("ul.steps")
    assert written_by_hand, "el preview tiene que traer los dos steppers"
    assert_equal squish_markup(written_by_hand), squish_markup(deciding_inside),
      "los dos steppers del preview tienen que rendir el mismo marcado"
  end

  # And they agree on the shape, not just with each other: one wrapper per
  # stepper, on the only step that has a detail.
  def test_only_the_step_with_a_detail_keeps_its_wrapper
    get "#{BASE}/with_content_block"

    assert_select "ul.steps", 2
    assert_select "li.step", 8
    assert_select "li.step > div", 2
    assert_select "li.step > div > span", 2
  end

  private

  # The two steppers are written at different indentation inside the preview
  # template, so their markup only has to agree once that is normalised — there
  # is no whitespace-sensitive element in a stepper.
  def squish_markup(node)
    node.inner_html.gsub(/\s+/, " ").strip
  end
end
