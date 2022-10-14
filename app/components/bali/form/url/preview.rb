# frozen_string_literal: true

module Bali
  module Form
    module Url
      class Preview < ApplicationViewComponentPreview
        def default
          render_with_template(
            template: 'bali/form/url/previews/default',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
