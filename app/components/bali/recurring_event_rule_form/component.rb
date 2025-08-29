# frozen_string_literal: true

module Bali
  module RecurringEventRuleForm
    class Component < ApplicationViewComponent
      def initialize(form, method, value, **options)
        @form = form
        @method = method
        @value = value
        @options = prepend_class_name(options, 'recurring-event-rule-form-component')
        @options = prepend_controller(options, 'recurring-event-rule')
      end

      private

      def timestamp
        @timestamp ||= Time.zone.now.to_f.to_s.gsub('.', '_')
      end

      def frequency_options
        [
          %w[Year 0],
          %w[Month 1],
          %w[Week 2],
          %w[Day 3],
          %w[Hour 4]
        ]
      end

      def ending_options
        [
          ['Never', ''],
          %w[After count],
          ['On date', 'until']
        ]
      end

      def bysetpos_options
        [
          %w[First 1],
          %w[Second 2],
          %w[Third 3],
          %w[Fourth 4],
          %w[Last -1]
        ]
      end

      def byweekday_options
        [
          %w[Sunday 6],
          %w[Monday 0],
          %w[Tuesday 1],
          %w[Wednesday 2],
          %w[Thursday 3],
          %w[Friday 4],
          %w[Saturday 5],
          %w[Day 6,0,1,2,3,4,5],
          %w[Weekday 0,1,2,3,4],
          ['Weekend day', '6,5']
        ]
      end

      def bymonth_options
        [
          %w[January 1],
          %w[February 2],
          %w[March 3],
          %w[April 4],
          %w[May 5],
          %w[June 6],
          %w[July 7],
          %w[August 8],
          %w[September 9],
          %w[October 10],
          %w[November 11],
          %w[December 12]
        ]
      end
    end
  end
end
