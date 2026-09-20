# frozen_string_literal: true

module DemoWidgets
  # THE RING LADDER: progress toward a goal, then how you got there.
  #
  # The ring REPLACES the number as the headline, which is what makes this a
  # pattern rather than a list with a decoration.
  class ProjectProgress < Bali::Widget::ProgressBase
    default_size :large
    refresh_every 20.seconds

    # ALL FOUR DECLARATIONS OFF ONE QUERY. Blocks are `instance_exec`'d on the
    # widget, so they can share a memoised private method — which is the point of
    # the block form and worth demonstrating here: the ring, its caption and the
    # chart underneath it were three separate round trips before.
    goal do |g|
      g.value { by_status.fetch("done", 0) }
      g.max { by_status.values.sum }
      g.label { I18n.t("widgets.project_progress.of_total", count: max) }
    end

    series do |s|
      s.labels { by_status.keys.map(&:humanize) }
      s.values { by_status.values }
    end

    private

    def by_status = @by_status ||= Task.group(:status).count
  end
end
