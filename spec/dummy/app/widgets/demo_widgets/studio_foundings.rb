# frozen_string_literal: true

module DemoWidgets
  # THE METRIC LADDER, the good-news direction. A count, how it moved, and the
  # history behind it — so `medium` shows the figure beside a sparkline and
  # `large` gives that chart its axes.
  #
  # The trend is a REAL comparison over real rows: studios founded in the most
  # recent full decade against the one before it. Nothing here is invented for
  # the demo, which matters — a showcase that fakes its own numbers teaches the
  # wrong thing about what the field is for.
  class StudioFoundings < Bali::Widget::Base
    include Rails.application.routes.url_helpers

    sized :medium

    def call
      list_from(Studio.order(founded_year: :desc), view_all_path: admin_studios_path) do |studio|
        Bali::Widget::Row.new(title: studio.name,
                              subtitle: subtitle(studio.founded_year, studio.country),
                              href: admin_studio_path(studio))
      end
        .with_series(labels: decades.keys.map(&:to_s), values: decades.values)
        .with(trend: founding_trend)
    end

    private

    # `{ 1890 => 2, 1910 => 3, … }` — eleven points of real variation, which is
    # what makes the sparkline worth drawing at all.
    def decades
      @decades ||= Studio.where.not(founded_year: nil)
                         .group(Arel.sql("(founded_year / 10) * 10"))
                         .count.sort.to_h
    end

    # More studios founded than in the decade before is good news, so the default
    # `positive_when: :up` is correct here — and `OverdueTasks` next door is the
    # widget that proves the opposite case is not the same thing.
    def founding_trend
      latest, previous = decades.values.last(2).reverse
      return if previous.nil? || previous.zero?

      Bali::Widget::Trend.new(
        delta: (((latest - previous) / previous.to_f) * 100).round,
        period: I18n.t("widgets.studio_foundings.period")
      )
    end
  end
end
