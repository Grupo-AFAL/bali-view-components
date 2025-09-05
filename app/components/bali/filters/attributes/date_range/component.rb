# frozen_string_literal: true

module Bali
  module Filters
    module Attributes
      module DateRange
        class Component < Bali::Filters::Attributes::Base::Component
          def initialize(form:, title:, attribute:, predicate:, **options)
            super(form: form, title: title, attribute: attribute, predicate: predicate)

            @time_period_options = options.delete(:time_period_options)
          end

          def datepicker_options
            opts = {
              controller: 'datepicker',
              datepicker_locale_value: I18n.locale,
              datepicker_mode_value: 'range',
              datepicker_static_value: true,
              datepicker_target: 'appendTo'
            }

            if @form.send(@attribute).respond_to?(:first)
              opts[:default_dates] = [@form.send(@attribute).first, @form.send(@attribute).first]
            end

            opts
          end
        end
      end
    end
  end
end
