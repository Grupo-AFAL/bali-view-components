# frozen_string_literal: true

# The dummy app's widget catalog — mirrors the pattern
# `docs/guides/engine-models.md` documents for a host's own list.
#
# JUST THE CONSTANT. `Bali::Concerns::Controllers::DashboardWidgets` is handed
# these CLASSES and instantiates and gates them itself; the
# `ALL.map { |k| k.new(user) }` wrapper every host used to write by hand lives
# there now.
module DemoWidgets
  # Ordered so the dashboard's default arrangement walks the ladders rather than
  # the alphabet: the compact facts first, then the two metric widgets that argue
  # opposite directions, then the ring, then the list widgets it all grew out of.
  ALL = [
    OverdueTasks,
    ProductionBudget,
    UnavailableFeed,
    ReleaseReadiness,
    SchemaHealth,
    RatingsAudit,
    ModernStudios,
    CatalogCoverage,
    StudioSizes,
    IndieStudios,
    StudioFoundings,
    TaskLoad,
    ProjectProgress,
    RecentMovies,
    ActiveStudios,
    UpcomingTasks,
    TopBudgetMovies
  ].freeze
end
