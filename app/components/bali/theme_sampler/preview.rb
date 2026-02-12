# frozen_string_literal: true

module Bali
  module ThemeSampler
    # Previews Bali components under different DaisyUI themes.
    # Switch the `theme` param to compare color palettes at a glance.
    class Preview < ApplicationViewComponentPreview
      layout 'lookbook_costa_norte'

      # @label Costa Norte Theme
      # Shows buttons, cards, alerts, badges, and form inputs
      # rendered under the Costa Norte brand theme.
      def costa_norte
        render_with_template(locals: { model: Movie.new })
      end
    end
  end
end
