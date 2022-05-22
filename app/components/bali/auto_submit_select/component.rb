# frozen_string_literal: true

module Bali
  module AutoSubmitSelect
    class Component < ApplicationViewComponent
      attr_reader :record, :attribute, :choices, :options

      def initialize(record:, attribute:, choices: [], **options)
        @record = record
        @attribute = attribute
        @choices = choices
        @options = prepend_controller(options, 'submit-on-change')
      end
    end
  end
end
