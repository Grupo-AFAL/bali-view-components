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

        def with_error
          model = Workout.new(validate_files: true)
          model.valid?

          render_with_template(
            template: 'bali/form/file/previews/with_error',
            locals: { model: model }
          )
        end

        def with_file_class
          render_with_template(
            template: 'bali/form/file/previews/with_file_class',
            locals: { model: form_record }
          )
        end

        def without_choose_text
          render_with_template(
            template: 'bali/form/file/previews/without_choose_text',
            locals: { model: form_record }
          )
        end

        def multiple
          render_with_template(
            template: 'bali/form/file/previews/multiple',
            locals: { model: form_record }
          )
        end

        # @label Narrow column
        # The field in a 240px column -- a sidebar, a drawer -- where the CTA and the file
        # name no longer fit on one row (#1370).
        def narrow
          render_with_template(
            template: 'bali/form/file/previews/narrow',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
