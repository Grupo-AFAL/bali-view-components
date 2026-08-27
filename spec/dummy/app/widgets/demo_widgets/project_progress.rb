# frozen_string_literal: true

module DemoWidgets
  # THE RING LADDER: progress toward a goal, then how you got there.
  #
  # The ring REPLACES the number as the headline, which is what makes this a
  # pattern rather than a list with a decoration.
  class ProjectProgress < Bali::Widget::ProgressBase
    default_size :large

    goal_label { I18n.t("widgets.project_progress.of_total", count: max) }

    series_labels { by_status.keys.map(&:humanize) }
    series_values { by_status.values }

    def value = Task.where(status: :done).count

    def max = Task.count

    private

    def by_status = @by_status ||= Task.group(:status).count
  end
end
