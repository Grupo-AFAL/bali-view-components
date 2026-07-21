# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SharedDateUtils
      WRAPPER_CLASS = "fieldset flatpickr"
      BUTTON_CLASS = "btn btn-ghost"
      JOIN_ITEM_CLASS = "join-item"
      CLEAR_BUTTON_CLASS = "#{BUTTON_CLASS} #{JOIN_ITEM_CLASS}".freeze
      NAV_BUTTON_CLASS = "#{BUTTON_CLASS} #{JOIN_ITEM_CLASS}".freeze

      # Maps flatpickr format tokens to a literal human hint for the auto-generated
      # `allow_input` placeholder. `F` (localized month name) is intentionally absent —
      # it has no universal literal hint, so it's handled via i18n instead (see
      # #allow_input_placeholder).
      ALT_FORMAT_PLACEHOLDER_TOKENS = {
        "d" => "dd", "j" => "d", "m" => "mm", "Y" => "yyyy",
        "H" => "HH", "h" => "hh", "i" => "MM", "S" => "ss", "K" => "AM/PM"
      }.freeze

      def date_field(method, options = {})
        opts = options.dup
        clear_btn = build_clear_button if opts.delete(:clear)
        opts[:control_class] = [ "w-full", opts[:control_class] ].compact.join(" ")
        # Typing is enabled by default (allow_input defaults to true in the
        # controller), so derive a placeholder hint for every field unless the
        # caller explicitly opts out with `allow_input: false` (readonly field,
        # no hint needed). An absent option counts as enabled.
        opts[:placeholder] ||= allow_input_placeholder(opts) unless opts[:allow_input] == false

        wrapper_options = build_wrapper_options(method, opts)

        # Format Range objects to string for the input value AFTER wrapper options are built
        if opts[:value].is_a?(Range)
          separator = { en: " to ", es: " a " }[I18n.locale.to_sym] || " to "
          opts[:value] = "#{opts[:value].first.strftime("%Y-%m-%d")}#{separator}#{opts[:value].last.strftime("%Y-%m-%d")}"
        end

        content_tag(:div, wrapper_options) do
          build_date_input(clear_btn, method, opts)
        end
      end

      def controller_values(method, options)
        values = {
          disable_weekends: options[:disable_weekends],
          min_date: options[:min_date],
          max_date: options[:max_date],
          alt_input_class: alt_input_class(method, options),
          mode: options[:mode],
          alt_input: options[:alt_input],
          allow_input: options[:allow_input],
          alt_format: options[:alt_format],
          disabled_dates: (options[:disabled_dates] || []).to_json
        }

        if options[:mode] == "range"
          if options[:value].respond_to?(:first) && !options[:value].is_a?(String)
            values[:default_dates] = [ options[:value].first, options[:value].last ]
          elsif options[:value].is_a?(String) && options[:value].present?
            # Split the range string using the localized separator
            separator = { en: " to ", es: " a " }[I18n.locale.to_sym] || " to "
            values[:default_dates] = options[:value].split(/#{Regexp.escape(separator)}/)
          end
        end

        values
      end

      private

      # Users can type directly into the visible input by default, but flatpickr
      # silently discards anything that doesn't match the effective altFormat on
      # blur (see datepicker-controller.js#altFormat). Without a hint, users have
      # no way to know what to type, so derive a placeholder from that same
      # effective format — unless the caller already supplied one.
      def allow_input_placeholder(options)
        effective_format = options[:alt_format].presence || default_alt_format(options)

        if effective_format.include?("F")
          I18n.t("bali.form_builder.date_fields.allow_input_placeholder")
        else
          effective_format.gsub(/[A-Za-z]/) { |token| ALT_FORMAT_PLACEHOLDER_TOKENS[token] || token }
        end
      end

      # Ruby port of DatepickerController#altFormat() in datepicker-controller.js,
      # so the derived placeholder always matches what the visible input actually
      # parses when no explicit `alt_format:` is given. Reads the same wrapper data
      # attributes the JS controller receives (enable_time/no_calendar/time_24hr/
      # seconds), before `build_wrapper_options` merges and removes `wrapper_options`.
      def default_alt_format(options)
        wrapper_data = (options[:wrapper_options] || {}).transform_keys(&:to_s)
        enable_time = wrapper_data["data-datepicker-enable-time-value"]
        no_calendar = wrapper_data["data-datepicker-no-calendar-value"]
        time_24hr = wrapper_data["data-datepicker-time24hr-value"]
        seconds = wrapper_data["data-datepicker-enable-seconds-value"]

        time_portion =
          if !no_calendar && !enable_time
            ""
          elsif seconds
            time_24hr ? "H:i:S" : "h:i:S K"
          else
            time_24hr ? "H:i" : "h:i K"
          end

        no_calendar ? time_portion : "d/m/Y #{time_portion}".strip
      end

      def build_clear_button
        aria_label = I18n.t("bali.form_builder.date_fields.clear", default: "Clear date")

        content_tag(:div, class: JOIN_ITEM_CLASS) do
          content_tag(:button, class: CLEAR_BUTTON_CLASS, type: "button",
                               data: { action: "datepicker#clear" },
                               'aria-label': aria_label) do
            @template.render(Bali::Icon::Component.new("times-circle"))
          end
        end
      end

      def build_wrapper_options(method, options)
        wrapper_class = class_names(WRAPPER_CLASS, "join" => options[:manual])

        wrapper_options = {
          class: wrapper_class,
          data: {
            controller: "datepicker",
            'datepicker-period-value': options[:period],
            'datepicker-locale-value': I18n.locale
          }
        }.merge!(options.delete(:wrapper_options) || {})

        cv = controller_values(method, options)
        prepend_values(wrapper_options, "datepicker", cv)
        wrapper_options
      end

      def build_date_input(clear_btn, method, options)
        if options[:manual]
          input = text_field(method, options)
          safe_join([ previous_date_button, input, next_date_button, clear_btn ].compact)
        else
          safe_join([ text_field(method, options), clear_btn ].compact)
        end
      end

      def alt_input_class(method, options)
        base_class = options[:alt_input_class] || "input input-bordered w-full"
        field_class_name(method, base_class)
      end

      def previous_date_button
        aria_label = I18n.t("bali.form_builder.date_fields.previous", default: "Previous date")

        content_tag(:button, @template.render(Bali::Icon::Component.new("arrow-back")),
                    class: NAV_BUTTON_CLASS,
                    type: "button",
                    data: { action: "datepicker#previousDate" },
                    'aria-label': aria_label)
      end

      def next_date_button
        aria_label = I18n.t("bali.form_builder.date_fields.next", default: "Next date")

        content_tag(:button, @template.render(Bali::Icon::Component.new("arrow-forward")),
                    class: NAV_BUTTON_CLASS,
                    type: "button",
                    data: { action: "datepicker#nextDate" },
                    'aria-label': aria_label)
      end
    end
  end
end
