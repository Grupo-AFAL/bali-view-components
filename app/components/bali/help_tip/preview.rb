# frozen_string_literal: true

module Bali
  module HelpTip
    class Preview < ApplicationViewComponentPreview
      # The help icon with a tooltip, packaged: the "?" next to a heading, a
      # label or a domain term. `FieldGroupWrapper` renders a field's `tooltip:`
      # option through this same component, so the icon next to a form label and
      # the one in a table header are one drawing.
      #
      # The trigger is keyboard-reachable out of the box (the tooltip controller
      # makes the wrapper a tab stop when the slot brings no focusable of its
      # own), and the balloon portals to `<body>` by default, so it escapes
      # clipping ancestors — the app shell's `<main>`, a drawer.
      #
      # @param text text
      # @param icon text
      # @param placement select { choices: [top, bottom, left, right] }
      def default(text: "Systematic overview of suppliers, inputs, process, outputs and customers.",
                  icon: "info-circle", placement: :top)
        render_with_template(locals: { text: text, icon: icon, placement: placement.to_sym })
      end
    end
  end
end
