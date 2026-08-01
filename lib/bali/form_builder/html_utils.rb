# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module HtmlUtils
      # Shared class for input addons (currency $, percentage %, etc.)
      ADDON_CLASSES = "btn btn-disabled pointer-events-none join-item"

      INPUT_BASE_CLASS = "input input-bordered w-full"
      INPUT_ADDON_BASE_CLASS = "input input-bordered join-item grow"
      TEXTAREA_BASE_CLASS = "textarea textarea-bordered w-full"

      PATTERN_TYPES = {
        number_with_commas: '^(\d+|\d{1,3}(,\d{3})*)(\.\d+)?$'
      }.freeze

      # Options the wrapper markup consumes: the fieldset legend, the help text
      # under the control, the `.control` div and the addons around the input.
      WRAPPER_OPTIONS = %i[
        label help control_class control_data addon_left addon_right addon_class
        field_class field_data
      ].freeze

      # Options a single helper consumes to decide what to build: the currency
      # symbol, the textarea's counter, the file input's copy, the step buttons'
      # data. All of them are read before the input is rendered.
      HELPER_OPTIONS = %i[
        pattern_type symbol char_counter auto_grow attachments select_class
        choose_file_text non_selected_text file_class icon
        subtract_data add_data button_class
      ].freeze

      # Options SharedDateUtils and TimeFields turn into `data-datepicker-*`
      # attributes on the flatpickr wrapper. They reach `text_field` because the
      # date helpers hand it the very same hash they received.
      DATEPICKER_OPTIONS = %i[
        clear manual period mode alt_input alt_input_class alt_format allow_input
        disable_weekends disabled_dates min_date max_date wrapper_options
        seconds time_24hr default_date min_time max_time
      ].freeze

      # The canonical list: every option Bali reads itself. None of them is a
      # valid HTML attribute, and Rails' tag helpers forward whatever they do not
      # recognise straight onto the element — so they all have to be gone before
      # the hash is delegated. Keys that ARE valid attributes (`class`, `type`,
      # `value`, `required`, `placeholder`, `min`, `max`, `step`, `multiple`,
      # `disabled`, `data`...) are deliberately absent, and so are the variant
      # keys a single family reuses under a different meaning (`size` and `color`
      # are daisyUI variants for a checkbox but real attributes on a text input);
      # those are stripped next to the helper that gives them that meaning.
      RESERVED_OPTIONS = (WRAPPER_OPTIONS + HELPER_OPTIONS + DATEPICKER_OPTIONS).freeze

      # The single extraction point. Everything that delegates to Rails goes
      # through here, so no module needs its own `delete`/`except` for the keys
      # above, and none of them can drift out of sync with this list.
      #
      # Returns a new hash every time: the caller's must come back untouched, or
      # reusing one options hash across two fields leaks the first field's
      # classes and Stimulus actions into the second.
      def html_attributes(options)
        options.except(*RESERVED_OPTIONS)
      end

      # `prepend_action` and friends mutate in place, and that includes the
      # nested `:data` hash — which `dup`, `except` and `merge` all leave
      # pointing at the caller's object. Copying that one key is what keeps a
      # second field from inheriting the first field's Stimulus actions.
      def dup_options(options)
        copy = options.dup
        copy[:data] = copy[:data].dup if copy[:data].is_a?(Hash)
        copy
      end

      def field_options(method, options)
        attributes = html_attributes(options)

        pattern_type = options[:pattern_type]
        attributes[:pattern] = PATTERN_TYPES[pattern_type] if pattern_type

        attributes[:class] = field_class_name(
          method, "#{input_base_class(options)} #{options[:class]}"
        )
        attributes
      end

      def textarea_field_options(method, options, stimulus: false)
        attributes = html_attributes(options)
        attributes[:class] = field_class_name(
          method, "#{TEXTAREA_BASE_CLASS} #{options[:class]}", error_class: "textarea-error"
        )

        if stimulus
          attributes[:data] = (attributes[:data] || {}).merge(
            "textarea-target" => "input", action: "input->textarea#onInput"
          )
        end

        attributes
      end

      # Escape hatch for non-model forms (issue #547): `input_name:` / `input_id:`
      # in the options hash override the name/id Rails derives from the form
      # object. Explicit `name:` / `id:` in html_options still win.
      def apply_input_name_options(options, html_options)
        html_options[:name] ||= options[:input_name] if options[:input_name]
        html_options[:id] ||= options[:input_id] if options[:input_id]
        html_options
      end

      def field_helper(method, field, options = {})
        help_message = help_message_for(method, options)

        left_addon = options[:addon_left]
        right_addon = options[:addon_right]

        # When addons exist, don't wrap in control div - use join pattern directly
        if left_addon.present? || right_addon.present?
          return field_with_addons(field, left: left_addon, right: right_addon) + help_message
        end

        control_class = [ "control", options[:control_class] ].compact.join(" ")
        wrapped_field = content_tag(
          :div, field, class: control_class, data: options[:control_data]
        )

        wrapped_field + help_message
      end

      def field_class_name(method, class_name = "input", error_class: "input-error")
        return class_name unless errors?(method)

        "#{class_name} #{error_class}"
      end

      def errors?(method)
        object.respond_to?(:errors) && object.errors.key?(method)
      end

      def full_errors(method)
        return "" unless object.respond_to?(:errors)

        safe_join(object.errors.full_messages_for(method), ", ")
      end

      # rubocop:disable Style/OptionalBooleanParameter
      #
      # This method is just a passthrough for the Rails method, so we can't really change the
      # signature of the method.
      def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &)
        @template.content_tag(name, content_or_options_with_block, options, escape, &)
      end
      # rubocop:enable Style/OptionalBooleanParameter

      # rubocop:disable Metrics/ParameterLists, Style/OptionalBooleanParameter
      def tag(name = nil, options = nil, open = false, escape = true)
        @template.tag(name, options, open, escape)
      end
      # rubocop:enable Metrics/ParameterLists, Style/OptionalBooleanParameter

      def safe_join(array, separator = nil)
        @template.safe_join(array, separator)
      end

      def translate_attribute(method)
        if object.respond_to?(:model_name)
          # `human_attribute_name` resolves through `activerecord.attributes.*`
          # for AR models and `activemodel.attributes.*` for plain
          # ActiveModel::Model form objects, falling back to humanize when
          # neither namespace has the key. Hardcoding `activerecord.*` missed
          # form-object translations entirely.
          object.class.human_attribute_name(method)
        else
          method.to_s.humanize
        end
      end

      private

      def help_message_for(method, options)
        if errors?(method)
          content_tag(:p, full_errors(method), class: "label-text-alt text-error")
        elsif options[:help]
          content_tag(:p, options[:help], class: "label-text-alt")
        end
      end

      # Add join-item class when addons are present for proper DaisyUI join pattern
      def input_base_class(options)
        has_addons = options[:addon_left].present? || options[:addon_right].present?

        has_addons ? INPUT_ADDON_BASE_CLASS : INPUT_BASE_CLASS
      end

      def field_with_addons(field, left:, right:)
        content_tag(:div, class: "join w-full") do
          @template.safe_join([ left, field, right ].compact)
        end
      end
    end
  end
end
