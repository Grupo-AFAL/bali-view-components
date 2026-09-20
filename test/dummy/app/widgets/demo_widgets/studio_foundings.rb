# frozen_string_literal: true

module DemoWidgets
  # THE TREND LADDER, the good-news direction. A figure, how it moved, and the
  # history behind it — so `medium` shows the number beside a sparkline and
  # `large` gives that chart its axes.
  #
  # The comparison is REAL: studios founded in the most recent full decade against
  # the one before. Nothing is invented for the demo — a showcase that fakes its
  # own numbers teaches the wrong thing about what the field is for.
  class StudioFoundings < Bali::Widget::TrendBase
    default_size :medium

    # More studios founded than in the decade before is good news, so the default
    # `:up` is right here. `TaskLoad` is the same ladder, inverted.
    trend do |t|
      t.current { decades.values.last }
      # NIL when there is only one decade on record — the trend is then absent
      # rather than zero, and `TrendBase` drops the rung for us.
      t.previous { decades.values[-2] }
      t.period_label "vs previous decade"
    end

    series do |s|
      s.labels { decades.keys.map(&:to_s) }
      s.values { decades.values }
    end

    private

    # `{ 1890 => 2, 1910 => 3, … }` — eleven points of real variation, which is
    # what makes the sparkline worth drawing. Memoised because `current`,
    # `previous` and both series blocks all read it.
    def decades
      @decades ||= Studio.where.not(founded_year: nil)
                         .group(Arel.sql("(founded_year / 10) * 10"))
                         .count.sort.to_h
    end
  end
end
