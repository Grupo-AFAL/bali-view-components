# frozen_string_literal: true

module Bali
  module Form
    module TimePeriod
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/time_period/previews/default',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
