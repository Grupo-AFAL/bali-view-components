# frozen_string_literal: true

module DemoWidgets
  # THE RING WITH A SPARKLINE BESIDE IT — the `medium` rung of the progress
  # ladder, which `ProjectProgress` shows at `large` with axes instead.
  #
  # The ring and the bars are the SAME SUBJECT, which is what the context region
  # is for: the ring says how many studios have a size on record, the bars say
  # how those split. A chart explaining a different fact than the headline is a
  # second widget wearing one card.
  class StudioSizes < Bali::Widget::ProgressBase
    include WidgetRoutes

    default_size :medium

    goal do |g|
      g.value { by_size.values.sum }
      g.max { Studio.count }
      g.label { "of #{Studio.count}" }
    end

    series do |s|
      s.labels { by_size.keys.map(&:humanize) }
      s.values { by_size.values }
    end

    view_all_path { admin_studios_path }

    private

    # Blank and nil both mean "not recorded", and neither is a size.
    def by_size = @by_size ||= Studio.where.not(size: [ nil, "" ]).group(:size).count
  end
end
