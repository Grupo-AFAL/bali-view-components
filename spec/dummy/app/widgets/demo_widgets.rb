# frozen_string_literal: true

# The dummy app's widget catalog — mirrors the pattern
# `docs/guides/engine-models.md` documents for a host's own `WIDGETS` list.
# `DashboardWidgetsController#offering` is the only caller.
module DemoWidgets
  ALL = [
    OverdueTasks,
    RecentMovies,
    ActiveStudios,
    UpcomingTasks,
    TopBudgetMovies
  ].freeze

  def self.authorized_for(user)
    Bali::Widget.authorized_for(ALL.map { |klass| klass.new(user) })
  end
end
