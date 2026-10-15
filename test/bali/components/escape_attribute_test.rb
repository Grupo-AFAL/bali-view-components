# frozen_string_literal: true

require "test_helper"

# Templates on the layout's hot path write their attributes by hand with escape_attribute and
# escape_data_attribute instead of `tag`. Each has to give the bytes `tag` gives for the same
# value, or the markup changes with no test of the component noticing.
class BaliEscapeAttributeTest < ComponentTestCase
  VALUES = [
    "plain", "", :symbol, 7, 1.5, true, false,
    %(q"<&>' x), %(q"<&>' x).html_safe, "caf\xC3\xA9", "bad \xFF byte"
  ].freeze

  def test_escape_attribute_writes_what_tag_writes
    VALUES.each do |value|
      assert_equal(view.tag.span(title: value), %(<span title="#{component.send(:escape_attribute, value)}"></span>),
                   "escape_attribute(#{value.inspect})")
    end
  end

  def test_escape_data_attribute_writes_what_tag_writes
    (VALUES + [ [ 1, "a" ], { a: "<b>" }, BigDecimal("1.50"), URI("https://example.com/a?b=1&c=2") ]).each do |value|
      assert_equal(view.tag.span(data: { x: value }),
                   %(<span data-x="#{component.send(:escape_data_attribute, value)}"></span>),
                   "escape_data_attribute(#{value.inspect})")
    end
  end

  private

  def view
    @view ||= vc_test_controller.view_context
  end

  def component
    @component ||= Bali::Icon::Component.new("user")
  end
end
