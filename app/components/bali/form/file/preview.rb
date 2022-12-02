# frozen_string_literal: true

module Bali
  module Form
    module File
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/file/previews/default',
            locals: { model: form_record }
          )
        end

        def with_field_class
          render_with_template(
            template: 'bali/form/file/previews/with_field_class',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
