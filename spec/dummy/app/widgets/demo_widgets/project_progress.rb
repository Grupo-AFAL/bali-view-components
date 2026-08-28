# frozen_string_literal: true

module DemoWidgets
  # THE RING LADDER: progress toward a goal, then how you got there.
  #
  # The ring REPLACES the number as the headline, which is what makes this a
  # pattern rather than a list with a decoration.
  class ProjectProgress < Bali::Widget::ProgressBase
    default_size :large

    goal do |g|
      g.value { Task.where(status: :done).count }
      g.max { Task.count }
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
