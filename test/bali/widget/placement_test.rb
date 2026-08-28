# frozen_string_literal: true

require "test_helper"

# A WIDGET AT A SIZE. Size is a per-owner arrangement fact rather than a
# property of the widget, so the pairing lives here and the card is TOLD which
# canvas to draw on.
class BaliWidgetPlacementTest < ActiveSupport::TestCase
  def widget(**overrides)
    Class.new(Bali::Widget::ValueBase) do
      def self.key = "k"
      default_size :small
      supports :small, :medium
      value { 1 }
    end.tap { |k| overrides.each { |m, v| k.public_send(m, *Array(v)) } }.new
  end

  def test_it_takes_the_stored_size
    assert_equal :medium, Bali::Widget::Placement.new(widget: widget, size: "medium").size
  end

  # The name arrives from a database column, so it can describe a size retired
  # between the save and the read. A dashboard that will not render is a worse
  # answer than one drawn at its default.
  def test_a_size_the_widget_no_longer_offers_falls_back_to_the_default
    assert_equal :small, Bali::Widget::Placement.new(widget: widget, size: "large").size
  end

  # Rows written before the size column existed carry nil.
  def test_no_stored_size_falls_back_to_the_default
    assert_equal :small, Bali::Widget::Placement.new(widget: widget).size
  end

  # So a placement can be looked up and ordered the way a widget was — the
  # resize path finds one by key.
  def test_it_answers_the_widgets_key
    assert_equal "k", Bali::Widget::Placement.new(widget: widget).key
  end
end
