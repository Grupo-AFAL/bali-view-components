# frozen_string_literal: true

module Bali
  module Gantt
    # The default status vocabulary of the Gantt (#704, trimmed by #970).
    #
    # Ruby used to carry the island's whole colour algebra — neutral/var/hue
    # formulas, the assignee hash — because the `:static` renderer painted bars
    # server-side with inline styles. That renderer is gone; the island computes
    # every colour itself (ganttColors.js) from the `catalogs` prop, and all the
    # server still decides is which daisyUI variable each default status maps to
    # when the host configures no catalog of its own.
    #
    # That map IS a shared frontier: ganttColors.js `defaultCatalogs.statuses`
    # has to agree with it, and
    # `test/bali/components/gantt/colors_test.rb` reads the JS and compares.
    module Colors
      # Status → daisyUI colour variable. nil = neutral (gray) treatment. Hosts
      # with other status vocabularies pass their own catalog to the component
      # instead of patching this.
      DEFAULT_STATUS_VARS = {
        "backlog" => nil,
        "in_progress" => "--color-info",
        "ready_for_review" => "--color-warning",
        "complete" => "--color-success",
        "cancelled" => nil
      }.freeze
    end
  end
end
