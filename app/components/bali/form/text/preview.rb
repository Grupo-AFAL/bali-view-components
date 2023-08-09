# frozen_string_literal: true

module Bali
  module Form
    module Text
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/text/previews/default',
            locals: { model: form_record }
          )
        end

        def with_errors
          form_record.errors.add(:text, :invalid)

          render_with_template(
            template: 'bali/form/text/previews/default',
            locals: { model: form_record }
          )
        end

        def with_addons
          render_with_template(
            template: 'bali/form/text/previews/with_addons',
            locals: { model: form_record }
          )
        end

        def with_addons_and_errors
          form_record.errors.add(:text, :invalid)

          render_with_template(
            template: 'bali/form/text/previews/with_addons',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
