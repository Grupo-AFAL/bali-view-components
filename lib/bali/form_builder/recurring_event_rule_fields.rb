# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module RecurringEventRuleFields
      def recurring_event_rule_field_group(method, options = {})
        @template.render Bali::FieldGroupWrapper::Component.new self, method, options do
          recurring_event_rule_field(method, options)
        end
      end

      def recurring_event_rule_field(method, options = {})
        value = options.delete(:value)

        tag.div(class: 'field', data: { controller: 'recurring-event-rule' }) do
          safe_join(
            [
              text_field(method, value: value, data: { recurring_event_rule_target: 'input' }),
              repeat_every_input_fields,
              freq_inputs,
              tag.hr,
              end_input_fields
            ]
          )
        end
      end

      private

      def repeat_every_input_fields
        tag.div(class: 'is-flex') do
          safe_join(
            [
              tag.p('Repeat every'),
              select_field(
                'frequency', frequency_options, {},
                data: {
                  rrule_attr: 'freq', input_active: true,
                  action: 'recurring-event-rule#toggleFreqInputsContainer ' \
                          'recurring-event-rule#toggleIntervalInput ' \
                          'recurring-event-rule#setRule'

                }
              ),
              tag.div(data: { recurring_event_rule_target: 'intervalInputContainer' }) do
                number_field(
                  'interval', value: 1, data: {
                    rrule_attr: 'interval', action: 'recurring-event-rule#setRule'
                  }
                )
              end
            ]
          )
        end
      end

      def end_input_fields
        tag.div(class: 'is-flex') do
          safe_join(
            [
              select_field(
                'end', ending_options, {},
                data: {
                  recurring_event_rule_target: 'endSelect',
                  action: 'recurring-event-rule#toggleEndInputsContainer ' \
                          'recurring-event-rule#setRule'
                }
              ),
              end_inputs
            ]
          )
        end
      end

      def end_inputs
        safe_join(
          [
            end_inputs_container(''),
            end_inputs_container('count') do
              number_field(
                'count',
                value: 1, min: 1,
                data: {  rrule_attr: 'count', action: 'recurring-event-rule#setRule' }
              )
            end,
            end_inputs_container('until') do
              date_field(
                'until', data: {
                  rrule_attr: 'until',
                  recurring_event_rule_target: 'untilInput',
                  action: 'recurring-event-rule#setRule'
                }
              )
            end
          ]
        )
      end

      def end_inputs_container(end_value, &)
        tag.div(
          class: 'is-hidden',
          data: { recurring_event_rule_target: 'endInputsContainer', end_value: end_value }, &
        )
      end

      def freq_inputs
        safe_join(
          [
            freq_inputs_container(0) { yearly_inputs },
            freq_inputs_container(1) { monthly_inputs },
            freq_inputs_container(2) { weekly_inputs },
            freq_inputs_container([3, 4])
          ]
        )
      end

      def freq_inputs_container(freq_value, &)
        tag.div(
          class: 'is-hidden',
          data: {
            recurring_event_rule_target: 'freqInputsContainer',
            rrule_freq: Array.wrap(freq_value).join(',')
          }, &
        )
      end

      def yearly_inputs
        timestamp = Time.zone.now.to_f.to_s.gsub('.', '_')
        safe_join(
          [
            tag.div(class: 'is-flex') do
              safe_join(
                [
                  tag.span do
                    safe_join(
                      [
                        @template.radio_button_tag(
                          "#{timestamp}_yearly_on", 1, true,
                          checked: true,
                          data: {
                            action: 'recurring-event-rule#toggleInputActiveAttribute ' \
                                    'recurring-event-rule#setRule'
                          }
                        ),
                        @template.label_tag("#{timestamp}_yearly_on_1", 'On')
                      ]
                    )
                  end,
                  tag.div(
                    data: { recurring_event_rule_target: 'freqOption',
                            rrule_freq_option: 'yearly_on_1' }
                  ) do
                    safe_join(
                      [
                        select_field('bymonth', bymonth_options, {},
                                     data: { rrule_attr: 'bymonth', action: 'recurring-event-rule#setRule' }),
                        select_field('bymonthday', (1..31).map(&:to_s), {},
                                     data: { rrule_attr: 'bymonthday', action: 'recurring-event-rule#setRule' })

                      ]
                    )
                  end
                ]
              )
            end,
            tag.div(class: 'is-flex') do
              safe_join(
                [
                  tag.span do
                    safe_join(
                      [
                        @template.radio_button_tag(
                          "#{timestamp}_yearly_on", 2, false, data:
                          { action: 'recurring-event-rule#toggleInputActiveAttribute ' \
                                    'recurring-event-rule#setRule' }
                        ),
                        @template.label_tag("#{timestamp}_yearly_on_2", 'On the')
                      ]
                    )
                  end,
                  tag.div(
                    data: { recurring_event_rule_target: 'freqOption',
                            rrule_freq_option: 'yearly_on_2' }
                  ) do
                    safe_join(
                      [
                        select_field('bysetpos', bysetpos_options, {},
                                     data: { rrule_attr: 'bysetpos', action: 'recurring-event-rule#setRule' }),
                        select_field('byweekday', byweekday_options, {},
                                     data: { rrule_attr: 'byweekday', action: 'recurring-event-rule#setRule' }),
                        select_field('bymonth', bymonth_options, {},
                                     data: { rrule_attr: 'bymonth', action: 'recurring-event-rule#setRule' })
                      ]
                    )
                  end
                ]
              )
            end
          ]
        )
      end

      def monthly_inputs
        timestamp = Time.zone.now.to_f.to_s.gsub('.', '_')
        safe_join(
          [
            tag.div(class: 'is-flex') do
              safe_join(
                [
                  tag.span do
                    safe_join(
                      [
                        @template.radio_button_tag(
                          "#{timestamp}_monthly_on", 1, true,
                          checked: true,
                          data: {
                            action: 'recurring-event-rule#toggleInputActiveAttribute ' \
                                    'recurring-event-rule#setRule'
                          }
                        ),
                        @template.label_tag("#{timestamp}_monthly_on_1", 'On day')
                      ]
                    )
                  end,
                  tag.div(
                    data: { recurring_event_rule_target: 'freqOption',
                            rrule_freq_option: 'monthly_on_1' }
                  ) do
                    select_field('bymonthday', (1..31).map(&:to_s), {},
                                 data: { rrule_attr: 'bymonthday', action: 'recurring-event-rule#setRule' })
                  end
                ]
              )
            end,
            tag.div(class: 'is-flex') do
              safe_join(
                [
                  tag.span do
                    safe_join(
                      [
                        @template.radio_button_tag(
                          "#{timestamp}_monthly_on", 2, false,
                          data: {
                            action: 'recurring-event-rule#toggleInputActiveAttribute ' \
                                    'recurring-event-rule#setRule'
                          }
                        ),
                        @template.label_tag("#{timestamp}_monthly_on_2", 'On the')
                      ]
                    )
                  end,
                  tag.div(
                    data: { recurring_event_rule_target: 'freqOption',
                            rrule_freq_option: 'monthly_on_2' }
                  ) do
                    safe_join(
                      [

                        select_field('bysetpos', bysetpos_options, {},
                                     data: { rrule_attr: 'bysetpos', action: 'recurring-event-rule#setRule' }),
                        select_field('byweekday', byweekday_options, {},
                                     data: { rrule_attr: 'byweekday', action: 'recurring-event-rule#setRule' })
                      ]
                    )
                  end
                ]
              )
            end

          ]
        )
      end

      def weekly_inputs_container(value, &)
        tag.div(
          class: 'is-hidden',
          data: { recurring_event_rule_target: 'freqInputsContainer', freq_value: value }, &
        )
      end

      def weekly_inputs
        timestamp = Time.zone.now.to_f.to_s.gsub('.', '_')

        tag.div(class: 'field') do
          safe_join(
            [
              @template.radio_button_tag(
                "#{timestamp}_weekly", 1, false, checked: true, class: 'is-hidden'
              ),
              tag.div(
                data: { recurring_event_rule_target: 'freqOption',
                        rrule_freq_option: 'weekly_1' }
              ) do
                safe_join(
                  [
                    ['SU', 6], ['MO', 0], ['TU', 1], ['WE', 2], ['TH', 3], ['FR', 4], ['SA', 5]
                  ].map do |day, value|
                    @template.check_box_tag(
                      "byweekday_#{timestamp}_[]", value, false,
                      id: "byweekday_#{timestamp}_#{day}",
                      data: { rrule_attr: 'byweekday', action: 'recurring-event-rule#setRule' }
                    ) +
                      @template.label_tag("byweekday_#{timestamp}_#{day}", day)
                  end
                )
              end
            ]
          )
        end
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
