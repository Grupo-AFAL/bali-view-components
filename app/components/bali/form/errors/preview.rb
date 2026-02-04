# frozen_string_literal: true

module Bali
  module Form
    module Errors
      class Preview < ApplicationViewComponentPreview
        # @label Default
        # Shows the error summary with multiple validation errors.
        def default
          model = form_record_with_errors
          render Bali::Form::Errors::Component.new(model: model)
        end

        # @label With Title
        # Shows the error summary with a custom title.
        def with_title
          model = form_record_with_errors
          render Bali::Form::Errors::Component.new(
            model: model,
            title: 'Please fix the following errors:'
          )
        end

        # @label In Form Context
        # Shows how to use error_summary within a form using the FormBuilder helper.
        def in_form_context
          render_with_template(
            template: 'bali/form/errors/previews/in_form_context',
            locals: { model: form_record_with_errors }
          )
        end

        # @label No Errors
        # When model has no errors, the component renders nothing.
        def no_errors
          render Bali::Form::Errors::Component.new(model: form_record)
        end

        private

        def form_record_with_errors
          record = form_record
          record.errors.add(:name, "can't be blank")
          record.errors.add(:email, 'is invalid')
          record.errors.add(:password, 'is too short (minimum is 8 characters)')
          record
        end
      end
    end
  end
end
