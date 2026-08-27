# frozen_string_literal: true

require "test_helper"

class BaliWidgetLayoutTest < ActiveSupport::TestCase
  def self.widget(key)
    Class.new(Bali::Widget::Base) do
      sized :medium
      define_singleton_method(:key) { key }
    end
  end

  ALPHA = widget("alpha")
  BRAVO = widget("bravo")

  def offering = [ ALPHA.new, BRAVO.new ]

  def params(hash) = ActionController::Parameters.new(hash)

  def test_turns_the_grid_payload_into_widgets_and_sizes
    layout = Bali::Widget::Layout.from(
      params(widgets: [ { key: "bravo", size: "large" }, { key: "alpha", size: "" } ]),
      offering: offering
    )

    assert_equal %w[bravo alpha], layout.map { |item| item[:widget].key }
    assert_equal [ "large", nil ], layout.map { |item| item[:size] }
  end

  # THE BOUNDARY. A key that is not in the already-authorized offering finds
  # nothing and is dropped — never rejected, so a role revoked between render and
  # submit degrades quietly, and a made-up key cannot be used to probe which keys
  # are real.
  def test_a_key_outside_the_offering_is_dropped_not_rejected
    layout = Bali::Widget::Layout.from(
      params(widgets: [ { key: "alpha" }, { key: "not_authorized" } ]),
      offering: offering
    )

    assert_equal %w[alpha], layout.map { |item| item[:widget].key }
  end

  # An emptied grid sends nothing, and no rows means "never chose" — so this is
  # the reset gesture rather than an error.
  def test_an_empty_submission_is_a_reset_rather_than_a_failure
    assert_empty Bali::Widget::Layout.from(params({}), offering: offering)
    assert_empty Bali::Widget::Layout.from(params(widgets: []), offering: offering)
  end

  def test_chosen_maps_picker_keys_to_widgets
    chosen = Bali::Widget::Layout.chosen(params(widget_keys: %w[bravo alpha]), offering: offering)

    assert_equal %w[bravo alpha], chosen.map(&:key)
  end

  def test_chosen_applies_the_same_boundary
    chosen = Bali::Widget::Layout.chosen(
      params(widget_keys: %w[alpha not_authorized]), offering: offering
    )

    assert_equal %w[alpha], chosen.map(&:key)
  end

  def test_chosen_with_nothing_ticked_is_empty
    assert_empty Bali::Widget::Layout.chosen(params({}), offering: offering)
  end
end
