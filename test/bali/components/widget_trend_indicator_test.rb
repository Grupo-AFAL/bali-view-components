# frozen_string_literal: true

require "test_helper"

class BaliWidgetTrendIndicatorComponentTest < ComponentTestCase
  def trend(**overrides)
    Bali::Widget::Trend.new(**{ delta: 12, period: "vs last week" }.merge(overrides))
  end

  def render_trend(compact: false, **overrides)
    render_inline(Bali::Widget::TrendIndicator::Component.new(trend(**overrides), compact: compact))
  end

  # THE RULE THIS COMPONENT EXISTS FOR, and the most misusable thing in the
  # widget contract. Overdue tasks up 12% and revenue up 12% are opposite news;
  # a component colouring from `direction` would paint half a dashboard's trends
  # the wrong way while looking confident about it.
  def test_a_rise_is_green_when_the_widget_says_rising_is_good
    render_trend(delta: 12, positive_when: :up)

    assert_selector(".text-success")
    assert_no_selector(".text-error")
  end

  def test_the_same_rise_is_red_when_the_widget_says_rising_is_bad
    render_trend(delta: 12, positive_when: :down)

    assert_selector(".text-error")
    assert_no_selector(".text-success")
  end

  def test_a_fall_is_green_when_the_widget_says_falling_is_good
    render_trend(delta: -12, positive_when: :down)

    assert_selector(".text-success")
  end

  # Painting "no change" green would say it was good news.
  def test_a_flat_trend_is_neither_good_nor_bad
    render_trend(delta: 0)

    assert_no_selector(".text-success")
    assert_no_selector(".text-error")
  end

  # The arrow describes the MOVEMENT, where the colour describes the meaning —
  # which is why one reads `direction` and the other does not.
  # Asserted on the decision rather than the markup: `Bali::Icon` inlines the
  # SVG, so the chosen name never appears in the rendered output.
  def test_the_arrow_follows_direction_even_when_the_news_is_bad
    bad_rise = Bali::Widget::TrendIndicator::Component.new(trend(delta: 12, positive_when: :down))

    assert_equal "trending-up", bad_rise.icon

    render_inline(bad_rise)

    assert_selector(".text-error")
  end

  def test_a_flat_trend_gets_neither_arrow
    assert_equal "minus", Bali::Widget::TrendIndicator::Component.new(trend(delta: 0)).icon
  end

  # The arrow is decorative, so the direction has to reach a screen reader as a
  # WORD or the trend announces as a bare number with no sign.
  def test_announces_the_direction_in_words
    render_trend(delta: 12)

    assert_selector(".sr-only", text: "up 12%")
  end

  # "↓ -67%" is a double negative that reads as a rise; the arrow carries the
  # sign, so the figure must not carry it too.
  def test_the_visible_delta_drops_the_sign_the_arrow_already_carries
    render_trend(delta: -67)

    assert_selector("[aria-hidden='true']", text: "67%")
    assert_no_text "-67%"
  end

  def test_a_widget_counting_things_can_drop_the_percent_sign
    render_trend(delta: 3, unit: "")

    assert_selector("[aria-hidden='true']", text: "3")
  end

  def test_renders_the_period_it_compares_against
    render_trend

    assert_text "vs last week"
  end

  # A ~215px tile has room for an arrow and a delta and nothing else.
  def test_compact_drops_the_period
    render_trend(compact: true)

    assert_no_text "vs last week"
    assert_selector("[aria-hidden='true']", text: "12%")
  end
end
