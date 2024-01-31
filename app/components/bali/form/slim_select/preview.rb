# frozen_string_literal: true

module Bali
  module Form
    module SlimSelect
      class Preview < ApplicationViewComponentPreview
        OPTIONS = [
          ['Option 1', 1],
          ['Option 2', 2],
          ['Option 3', 3],
          ['Option 4', 4],
          ['Option 5', 5]
        ].freeze

        def default
          render_with_template(
            template: 'bali/form/slim_select/previews/default',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        def addable
          render_with_template(
            template: 'bali/form/slim_select/previews/addable',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        def remote
          render_with_template(
            template: 'bali/form/slim_select/previews/remote',
            locals: { model: form_record, options: OPTIONS }
          )
        end
      end
    end
  end
end
