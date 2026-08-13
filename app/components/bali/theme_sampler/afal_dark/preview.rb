# frozen_string_literal: true

module Bali
  module ThemeSampler
    module AfalDark
      # Previews Bali components under the DRAFT afal-dark theme
      # (css/themes/afal-dark.css). Same sampler template as the AFAL light
      # preview, different layout — flip between the two to compare the
      # palettes on identical content. This is the visual gate for the draft:
      # the theme is experimental until it is approved here.
      class Preview < ApplicationViewComponentPreview
        layout "lookbook_afal_dark"

        # @label AFAL Dark Theme (draft)
        # The draft dark variant rendered over the same content as the AFAL
        # light preview.
        def default
          render_with_template(
            template: "bali/theme_sampler/afal/previews/default",
            locals: { model: Movie.new }
          )
        end
      end
    end
  end
end
