# frozen_string_literal: true

module Bali
  module AutoSubmitSelect
    include HtmlElementHelper

    def auto_submit_select(record:, attribute:, choices:, **options)
      options = prepend_controller(options, 'submit-on-change')

      form_with model: record, builder: Bali::FormBuilder, **options do |f|
        f.select_field attribute, choices,
                       { show_search: false },
                       { data: { action: 'submit-on-change#submit' } }
      end
    end
  end
end
