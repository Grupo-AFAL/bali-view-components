# frozen_string_literal: true

module Bali
  module Form
    module TimePeriod
      # Time Period Field - Select predefined date ranges instead of picking exact dates.
      #
      # Common use cases:
      # - Dashboard date filters ("Last 7 days", "This month")
      # - Report period selectors ("Q1 2026", "January")
      # - Scheduling interfaces ("This week", "Next week")
      #
      # The field combines a dropdown with predefined periods and a hidden date picker
      # that appears when "Custom" is selected.
      class Preview < ApplicationViewComponentPreview
        # @label Quarterly Report Filter
        # Use `SelectOptions.yearly_quarter` for financial/business reports.
        # Returns the current year + Q1-Q4 quarters.
        #
        # ```ruby
        # form.time_period_field_group :period, Bali::TimePeriods::SelectOptions.yearly_quarter
        # ```
        def quarterly_report
          render_with_template(
            template: 'bali/form/time_period/previews/quarterly_report',
            locals: { model: form_record }
          )
        end

        # @label Monthly Filter with Custom
        # Use `SelectOptions.months` for monthly reports.
        # Add `include_blank: 'Custom'` to allow users to pick any date range.
        #
        # When "Custom" is selected, a date range picker appears.
        #
        # ```ruby
        # form.time_period_field_group :period, Bali::TimePeriods::SelectOptions.months,
        #                              include_blank: 'Custom'
        # ```
        def monthly_with_custom
          render_with_template(
            template: 'bali/form/time_period/previews/monthly_with_custom',
            locals: { model: form_record }
          )
        end

        # @label Week Selector
        # Custom options for week-based selection (scheduling, availability).
        #
        # ```ruby
        # form.time_period_field :period, [
        #   ['Next week', 1.week.from_now.all_week],
        #   ['This week', Time.zone.now.all_week],
        #   ['Last week', 1.week.ago.all_week]
        # ], selected: Time.zone.now.all_week
        # ```
        def week_selector
          render_with_template(
            template: 'bali/form/time_period/previews/week_selector',
            locals: { model: form_record }
          )
        end

        # @label Trailing Periods (Analytics)
        # Use `SelectOptions.trailing` for analytics dashboards.
        # Returns: Yesterday, Last 7 days, Last 30 days, Last 12 weeks, Last 12 months.
        #
        # ```ruby
        # form.time_period_field_group :period, Bali::TimePeriods::SelectOptions.trailing,
        #                              include_blank: 'Custom range'
        # ```
        def trailing_periods
          render_with_template(
            template: 'bali/form/time_period/previews/trailing_periods',
            locals: { model: form_record }
          )
        end
      end
    end
  end
end
