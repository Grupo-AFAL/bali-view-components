# frozen_string_literal: true

module Bali
  module Form
    module Datetime
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Datetime picker with both date and time selection enabled.
        # Uses Flatpickr with `enableTime: true`.
        def default
          render_with_template(
            template: 'bali/form/datetime/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Initial Value
        # Datetime field pre-populated with a value.
        def with_value
          record = form_record
          # `::Time` is mandatory here: the lexical scope of this preview includes
          # `Bali::Form`, where `Bali::Form::Time` (the time field component) shadows
          # the top-level `Time`.
          record.datetime = ::Time.current
          render_with_template(
            template: 'bali/form/datetime/previews/default',
            locals: { model: record }
          )
        end
      end
    end
  end
end
