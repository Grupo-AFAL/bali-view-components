# frozen_string_literal: true

module Bali
  module Form
    module RecurringEventRule
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/recurring_event_rule/previews/default',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
