# frozen_string_literal: true

module Bali
  module ThemeSampler
    module Afal
      # Previews Bali components under the AFAL brand theme shipped with the
      # gem (css/themes/afal.css). One preview class per theme because the
      # layout — where `data-theme` lands on <html> — is class-level in
      # Lookbook: there is no per-example layout.
      class Preview < ApplicationViewComponentPreview
        layout "lookbook_afal"

        # @label AFAL Theme
        # Buttons, cards, alerts, badges and form inputs rendered under the
        # AFAL brand theme (light).
        def default
          render_with_template(locals: { model: Movie.new })
        end
      end
    end
  end
end
