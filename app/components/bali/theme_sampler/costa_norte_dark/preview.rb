# frozen_string_literal: true

module Bali
  module ThemeSampler
    module CostaNorteDark
      # Previews Bali components under the costa-norte-dark theme
      # (css/themes/costa-norte-dark.css). Same sampler template as the Costa Norte
      # light preview, different layout — flip between the two to compare the
      # palettes on identical content.
      class Preview < ApplicationViewComponentPreview
        layout "lookbook_costa_norte_dark"

        # @label Costa Norte Dark Theme
        # The dark variant rendered over the same content as the Costa Norte
        # light preview.
        def default
          render_with_template(
            template: "bali/theme_sampler/previews/costa_norte",
            locals: { model: Movie.new }
          )
        end
      end
    end
  end
end
