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
    include NumericFields
    include PasswordFields
    include PercentageFields
    include RadioFields
    include RangeFields
    include RecurrentEventRuleFields
    include RichTextAreaFields
    include RichTextFields
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

    # Last, so the v2 spellings it defines are unambiguously the compatibility
    # layer and not part of any family. The whole module goes in 4.0.
    include DeprecatedNames
  end
end
