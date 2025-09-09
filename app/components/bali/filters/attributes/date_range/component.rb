# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module DateRange
        class Component < Bali::Filters::Attributes::Base::Component
          def initialize(form:, title:, attribute:, include_custom_time_period: true, **options)
            super(form: form, title: title, attribute: attribute)

            @time_period_options = options.delete(:time_period_options)
            @include_custom_time_period = include_custom_time_period
          end

          def datepicker_options
            opts = {
              controller: 'datepicker',
              datepicker_locale_value: I18n.locale,
              datepicker_mode_value: 'range',
              datepicker_static_value: true,
              datepicker_target: 'appendTo'
            }

            opts[:datepicker_default_dates_value] =
              if selected_value.is_a?(Array) && selected_value.first && selected_value.last
                [selected_value.first, selected_value.last]
              elsif selected_value.is_a?(Range) && selected_value.begin && selected_value.end
                [selected_value.begin, selected_value.end]
              end

            opts
          end

          def selected_value
            @form.send(@attribute)
          end
        end
      end
    end
  end
end
