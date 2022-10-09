# frozen_string_literal: true

module Bali
  module Form
    module Date
      class Preview < ApplicationViewComponentPreview
        def date_field_group
          render_with_template(
            template: 'bali/form/date/field_group',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
