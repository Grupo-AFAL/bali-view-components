# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    include HtmlElementHelper
    include SharedUtils
    include SharedDateUtils
    include Utils
    include HtmlUtils

    include BooleanFields
    include CoordinatesPolygonFields
    include CurrencyFields
    include DateFields
    include DatetimeFields
    include DirectUploadFields
    include DynamicFields
    include EmailFields
    include ErrorSummaryFields
    include FileFields
    include NumberFields
    include PasswordFields
    include PercentageFields
    include RadioFields
    include RangeFields
    include RecurrentEventRuleFields
    include RichTextAreaFields
    include SearchFields
    include SelectFields
    include SlimSelectFields
    include StepNumberFields
    include SubmitFields
    include SwitchFields
    include TextAreaFields
    include TextFields
    include TimeFields
    include TimePeriodFields
    include TimeZoneSelectFields
    include UrlFields
  end
end
