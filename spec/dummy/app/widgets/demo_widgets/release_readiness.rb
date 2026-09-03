# frozen_string_literal: true

module DemoWidgets
  # THE CHECK LADDER: one fact with two answers, and a third for "not yet known".
  #
  # Phrased so TRUE IS GOOD — "ready", not "blocked" — which is what lets the
  # card colour itself without a `positive_when` declaration. A check named the
  # other way round would render a green tick for bad news.
  class ReleaseReadiness < Bali::Widget::CheckBase
    include WidgetRoutes

    default_size :small

    check do |c|
      # NIL, not false, when there is nothing to judge: no tasks means the
      # question has no answer yet, and the card draws the muted third state
      # rather than claiming a pass.
      c.value { blockers.nil? ? nil : blockers.zero? }
      c.pass { "Ready to ship" }
      c.fail { "#{blockers} blocking" }
    end

    view_all_path { admin_projects_path }

    private

    def blockers
      @blockers ||= begin
        scope = Task.where(priority: :high).where.not(status: :done)
        Task.exists? ? scope.count : nil
      end
    end
  end
end
