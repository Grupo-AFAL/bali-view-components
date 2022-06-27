# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    include HtmlElementHelper
    include SharedFormBuilderUtils
    include Utils
    include FormBuilderHelpers::BooleanFields
    include FormBuilderHelpers::CurrencyFields
    include FormBuilderHelpers::DateFields
    include FormBuilderHelpers::DatetimeFields
    include FormBuilderHelpers::DynamicFields
    include FormBuilderHelpers::EmailFields
    include FormBuilderHelpers::FileFields
    include FormBuilderHelpers::NumberFields
    include FormBuilderHelpers::PasswordFields
    include FormBuilderHelpers::PercentageFields
    include FormBuilderHelpers::RadioFields
    include FormBuilderHelpers::RichTextAreaFields
    include FormBuilderHelpers::SearchFields
    include FormBuilderHelpers::SelectFields
    include FormBuilderHelpers::SlimSelectFields
    include FormBuilderHelpers::StepNumberFields
    include FormBuilderHelpers::SubmitFields
    include FormBuilderHelpers::TextAreaFields
    include FormBuilderHelpers::TextFields
    include FormBuilderHelpers::TimeFields
    include FormBuilderHelpers::TimeZoneSelectFields
  end
end
