# frozen_string_literal: true

module Bali
  module Form
    module CoordinatesPolygon
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/coordinates_polygon/previews/default',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
