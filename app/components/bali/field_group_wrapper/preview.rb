# frozen_string_literal: true

module Bali
  module FieldGroupWrapper
    class Preview < ApplicationViewComponentPreview

      def default
        render_with_template(
          template: 'bali/field_group_wrapper/previews/default',
          locals: { model: form_record }
        )
      end
    end
  end
end
