# frozen_string_literal: true

module Bali
  module Form
    module Url
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows a basic URL input field with DaisyUI styling.
        def default
          render_with_template(
            template: 'bali/form/url/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Errors
        # Shows the URL field with validation error styling.
        def with_errors
          form_record.errors.add(:url, :invalid)

          render_with_template(
            template: 'bali/form/url/previews/default',
            locals: { model: form_record }
          )
        end

        # @label With Addons
        # Shows URL field with protocol prefix addon using DaisyUI join pattern.
        def with_addons
          render_with_template(
            template: 'bali/form/url/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Addons and Errors
        # Shows URL field with addons and validation error.
        def with_addons_and_errors
          form_record.errors.add(:url, :invalid)

          render_with_template(
            template: 'bali/form/url/previews/with_addons',
            locals: { model: form_record }
          )
        end

        # @label With Help Text
        # Shows URL field with help text below the input.
        def with_help_text
          render_with_template(
            template: 'bali/form/url/previews/with_help_text',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
