# frozen_string_literal: true

# The dummy app's widget catalog — mirrors the pattern
# `docs/guides/engine-models.md` documents for a host's own `WIDGETS` list.
# `DashboardWidgetsController#offering` is the only caller.
module DemoWidgets
  # Ordered so the dashboard's default arrangement walks the ladders rather than
  # the alphabet: the compact facts first, then the two metric widgets that argue
  # opposite directions, then the ring, then the list widgets it all grew out of.
  ALL = [
    OverdueTasks,
    ProductionBudget,
    UnavailableFeed,
    StudioFoundings,
    TaskLoad,
    ProjectProgress,
    RecentMovies,
    ActiveStudios,
    UpcomingTasks,
    TopBudgetMovies
  ].freeze

  def self.authorized_for(user)
    Bali::Widget.authorized_for(ALL.map { |klass| klass.new(user) })
  end
end
