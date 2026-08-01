# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module HtmlUtils
      # Shared class for input addons (currency $, percentage %, etc.)
      ADDON_CLASSES = "btn btn-disabled pointer-events-none join-item"

      INPUT_BASE_CLASS = "input w-full"
      INPUT_ADDON_BASE_CLASS = "input join-item grow"
      TEXTAREA_BASE_CLASS = "textarea w-full"

      # daisyUI 5 dropped `label-text-alt`; `fieldset-label` is its successor for
      # the messages under a control. Unlike `.label` — the other candidate — it
      # is a block-level flex container with no `white-space: nowrap`, so a long
      # validation message wraps instead of overflowing the fieldset.
      MESSAGE_CLASS = "fieldset-label"
      ERROR_MESSAGE_CLASS = "fieldset-label text-error"

      PATTERN_TYPES = {
        number_with_commas: '^(\d+|\d{1,3}(,\d{3})*)(\.\d+)?$'
      }.freeze

      # Options the wrapper markup consumes: the fieldset caption, the help text
      # under the control, the `.control` div and the addons around the input.
      # `control_id` is the id the caption's `for` points at — read by
      # FieldGroupWrapper, never an attribute of the input itself.
      WRAPPER_OPTIONS = %i[
        label help control_class control_data addon_left addon_right addon_class
        field_class field_data control_id
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

      # The id the control is really going to carry, so the wrapper's
      # `<label for>` and the input's `aria-describedby` can name it instead of
      # each rebuilding a guess of their own. A `for` pointing at an id nobody
      # emits looks perfect in the HTML and gives the control no name at all.
      #
      # Rails derives the default from the object name, the index and the
      # method, which is what makes two forms for the same model on one page
      # produce distinct ids as long as they are namespaced or indexed. An
      # explicit `id:` and `input_id:` (the non-model escape hatch of #547)
      # override it, in that order, because that is the order the helpers
      # themselves resolve them in.
      def control_id(method, options = {})
        options[:id].presence || options[:input_id].presence || field_id(method)
      end

      # The id of the caption FieldGroupWrapper renders. Both sides derive it
      # from `field_id`, so a widget that cannot be named by a `<label for>` —
      # anything that is not a labelable element, such as Trix's `<trix-editor>` —
      # can still point an `aria-labelledby` at the very same caption without the
      # wrapper having to hand it down through the render block.
      def label_id(method)
        field_id(method, "label")
      end

      # nil when no caption will be rendered, so nothing ever points an
      # `aria-labelledby` at an id that is not in the document. `label: false`
      # and `label: { text: false }` are the two spellings that turn it off, and
      # a hidden field never gets one.
      def caption_id(method, options = {})
        return if options[:type].to_s == "hidden"

        label = options[:label]
        return if label == false || (label.is_a?(Hash) && label[:text] == false)

        label_id(method)
      end

      # `aria-describedby` may only name ids that exist. The error and help
      # paragraphs are in the DOM only when there is something to say, so this
      # is built from exactly what `error_and_help` is about to render — never
      # from what the field *could* have.
      def aria_attributes(method, options = {})
        described_by = [
          (error_message_id(method) if errors?(method)),
          (help_message_id(method) if options[:help].present?)
        ].compact

        {
          "aria-describedby": described_by.presence&.join(" "),
          "aria-invalid": ("true" if errors?(method))
        }.compact
      end

      # Drops Bali's aria pair onto an attribute hash, skipping anything the
      # caller already spelled by hand. Rails accepts both `aria: { invalid: }`
      # and `"aria-invalid" =>`, and writing both spellings emits the attribute
      # twice, so both are checked before anything is added.
      def merge_aria_attributes(attributes, method, options = {})
        nested = attributes[:aria].is_a?(Hash) ? attributes[:aria] : {}

        aria_attributes(method, options).each do |key, value|
          short = key.to_s.delete_prefix("aria-").to_sym
          next if attributes.key?(key) || nested.key?(short)

          attributes[key] = value
        end

        attributes
      end

      def field_options(method, options)
        attributes = html_attributes(options)

        pattern_type = options[:pattern_type]
        attributes[:pattern] = PATTERN_TYPES[pattern_type] if pattern_type

        attributes[:class] = field_class_name(
          method, "#{input_base_class(options)} #{options[:class]}"
        )
        merge_aria_attributes(attributes, method, options)
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

        merge_aria_attributes(attributes, method, options)
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
        messages = error_and_help(method, options)

        left_addon = options[:addon_left]
        right_addon = options[:addon_right]

        # When addons exist, don't wrap in control div - use join pattern directly
        if left_addon.present? || right_addon.present?
          return field_with_addons(field, left: left_addon, right: right_addon) + messages
        end

        control_class = [ "control", options[:control_class] ].compact.join(" ")
        wrapped_field = content_tag(
          :div, field, class: control_class, data: options[:control_data]
        )

        wrapped_field + messages
      end

      # The one place the builder renders what it has to say about a field.
      # Every family goes through it — checkboxes, toggles, ranges, and every
      # helper behind `field_helper` — so the markup cannot drift again.
      #
      # Both messages render. The error says what went wrong; the help still
      # says what is expected, and a wrong field is the one moment the user
      # needs that instruction most. The error comes first so it keeps sitting
      # right under the control, where it has always been.
      #
      # Each message carries a stable id, which is what #674 needs to point the
      # control's `aria-describedby` at them. Emitting the id is all that
      # happens here; wiring it onto the input belongs to that issue.
      def error_and_help(method, options = {})
        safe_join([ error_message(method), help_message(method, options) ].compact)
      end

      def error_message(method)
        return unless errors?(method)

        content_tag(
          :p, full_errors(method), class: ERROR_MESSAGE_CLASS, id: error_message_id(method)
        )
      end

      def help_message(method, options = {})
        help = options[:help]
        return if help.blank?

        content_tag(:p, help, class: MESSAGE_CLASS, id: help_message_id(method))
      end

      # Derived with Rails' own `field_id`, so the ids follow the same namespace,
      # index and nested-attribute rules as the control they describe.
      def error_message_id(method)
        field_id(method, "error")
      end

      def help_message_id(method)
        field_id(method, "help")
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
