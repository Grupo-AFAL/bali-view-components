# frozen_string_literal: true

module Bali
  module Form
    module RecurrentEventRule
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/recurrent_event_rule/previews/default',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
