# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module HtmlUtils
      # Shared class for input addons (currency $, percentage %, etc.)
      ADDON_CLASSES = "btn btn-disabled pointer-events-none join-item"

      INPUT_BASE_CLASS = "input w-full"
      INPUT_ADDON_BASE_CLASS = "input join-item grow"
      TEXTAREA_BASE_CLASS = "textarea w-full"

      # `size:` is the one key with two legitimate meanings on a form control:
      # daisyUI's density variant and the HTML attribute of the same name (width
      # in characters on an `<input>`, visible rows on a `<select>`). A Symbol
      # out of the family's map is the variant; an Integer — or a String, which
      # is what `size: "4"` has always meant — keeps meaning the attribute and
      # passes through untouched. See `size_variant`.
      #
      # One map per daisyUI component, spelled out rather than interpolated:
      # Tailwind scans `lib/bali/**/*.rb` for class names, and a class it only
      # ever sees assembled at runtime is a class it does not compile.
      # The families whose control is its own daisyUI component keep their map
      # next to the family (`RangeFields::SIZES`, `BooleanFields::SIZES`,
      # `SwitchFields::SIZES`, `RadioFields::SIZES`, `SlimSelectFields::SIZES`,
      # `FileFields::CTA_SIZES`); these three are the ones `html_utils` itself
      # resolves for every family that shares the base classes above.
      INPUT_SIZES = {
        xs: "input-xs", sm: "input-sm", md: "input-md", lg: "input-lg", xl: "input-xl"
      }.freeze

      SELECT_SIZES = {
        xs: "select-xs", sm: "select-sm", md: "select-md", lg: "select-lg", xl: "select-xl"
      }.freeze

      TEXTAREA_SIZES = {
        xs: "textarea-xs", sm: "textarea-sm", md: "textarea-md",
        lg: "textarea-lg", xl: "textarea-xl"
      }.freeze

      # daisyUI 5 dropped `label-text-alt`; `fieldset-label` is its successor for
      # the messages under a control. Unlike `.label` — the other candidate — it
      # is a block-level flex container with no `white-space: nowrap`, so a long
      # validation message wraps instead of overflowing the fieldset.
      MESSAGE_CLASS = "fieldset-label"
      ERROR_MESSAGE_CLASS = "fieldset-label text-error"

      # `number_with_commas` keeps its old name — it is the value hosts already
      # pass — but it no longer means "commas". Both separators are read from the
      # active locale at render time, so the same option yields `1,234.56` in
      # English and `1.234,56` wherever the host ships Spanish number formats.
      # The old frozen literal accepted only the English shape, which is what
      # rejected every correctly-typed Spanish amount. `localized_number` is the
      # name that says so.
      PATTERN_TYPES = %i[number_with_commas localized_number].freeze

      # Options the wrapper markup consumes: the fieldset caption, the help text
      # under the control, the `.control` div and the addons around the input.
      # `control_id` is the id the caption's `for` points at — read by
      # FieldGroupWrapper, never an attribute of the input itself. `error` is
      # the caller's own message for the field — rendered by `error_and_help`
      # next to the model's, never an attribute.
      WRAPPER_OPTIONS = %i[
        label help error control_class control_data addon_left addon_right addon_class
        field_class field_data control_id
      ].freeze

      # Options a single helper consumes to decide what to build: the currency
      # symbol, the textarea's counter, the file input's copy, the step buttons'
      # data, the caption a checkbox or a toggle renders beside itself. All of
      # them are read before the input is rendered.
      HELPER_OPTIONS = %i[
        pattern_type symbol char_counter auto_grow attachments select_class
        choose_file_text non_selected_text file_class icon
        subtract_data add_data button_class text
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

      # Attributes that only mean something on a native form control, dropped by
      # the families that render something else. Both reached them because both
      # are real attributes on an `<input>` and therefore deliberately absent
      # from the list above — but a block editor, a Trix editor, a polygon map
      # and a period picker are each a widget over a hidden field.
      #
      # `required`: a hidden input is barred from constraint validation to begin
      # with, and a submit button is a control the browser never validates.
      # Measured helper by helper before this list existed: `<div required>` on
      # two of them and `<trix-editor required>` on a third — none of which is
      # valid or does anything — and silence on the rest. Every outcome reads as
      # "this field is required" at the call site and none of them made it so.
      #
      # `size`: valid on `<input>` and `<select>` only, so on those same widgets
      # it painted `<div size="sm">` — measured on four of them while the sweep
      # in `size_option_test.rb` was written (#723). SlimSelect drops it for the
      # reason it drops `required`: its `<select>` is clipped to 1x1, so visible
      # rows are as meaningless there as a validation bubble.
      CONTROL_ONLY_OPTIONS = %i[required size].freeze

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

      # `html_attributes` for a family that renders a widget rather than a
      # control. See CONTROL_ONLY_OPTIONS.
      def widget_attributes(options)
        html_attributes(options).except(*CONTROL_ONLY_OPTIONS)
      end

      # The keys the field *group* owns — the caption, the help text, the addons,
      # the `.control` div — gathered from every hash the helper takes.
      #
      # A family with a single options hash never had a problem. The ones that
      # take a second positional hash each decided on their own which of the two
      # `field_helper` would see, and the three select families chose the last
      # one: `help:` written next to `label:`, where anyone would write it,
      # reached the wrapper and never reached the paragraph, so it vanished with
      # no error and no warning. Measured before the fix — `select_group`,
      # `slim_select_group` and `time_zone_select_group` dropped it; the other
      # nine field types rendered it.
      #
      # The first hash wins on a conflict: it is the caller's primary one, the
      # one holding `label:`.
      def group_options(options, *others)
        others.compact.each_with_object(options.dup) do |other, merged|
          other.slice(*WRAPPER_OPTIONS).each do |key, value|
            merged[key] = value unless merged.key?(key)
          end
        end
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

      # The caption a checkbox or a toggle renders beside itself, inside the
      # `<label>` that wraps the control — the one the accessible name comes
      # from. It is a separate key from `label:` because the two are separate
      # captions: this one sits next to the box, `label:` is the `<legend>`
      # naming the group. `text: false` drops it, for the caller who wants the
      # legend to be the only name in the field.
      def inline_caption(method, options = {})
        text = options.fetch(:text) { translate_attribute(method) }
        return if text == false

        content_tag(:span, text)
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
          (error_message_id(method) if errors?(method, options)),
          (help_message_id(method) if options[:help].present?)
        ].compact

        {
          "aria-describedby": described_by.presence&.join(" "),
          "aria-invalid": ("true" if errors?(method, options))
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

      # The thousands delimiter and the decimal separator of the active locale,
      # escaped for use inside a character-by-character pattern. Built per call,
      # never frozen into a constant: the locale is only known at render time,
      # and a constant would bake whichever locale happened to be active when
      # the class was loaded into every request that followed.
      #
      # The `default:` pair is Rails' own English fallback, so a host without
      # rails-i18n keeps exactly the pattern it had before.
      def localized_number_pattern
        delimiter = Regexp.escape(I18n.t("number.format.delimiter", default: ","))
        separator = Regexp.escape(I18n.t("number.format.separator", default: "."))

        "^(\\d+|\\d{1,3}(#{delimiter}\\d{3})*)(#{separator}\\d+)?$"
      end

      def field_options(method, options)
        attributes = html_attributes(options)
        attributes.delete(:size) if size_variant(options)

        if PATTERN_TYPES.include?(options[:pattern_type])
          attributes[:pattern] = localized_number_pattern
        end

        attributes[:class] = field_class_name(
          method, "#{input_base_class(options)} #{options[:class]}", options: options
        )
        merge_aria_attributes(attributes, method, options)
      end

      def textarea_field_options(method, options, stimulus: false)
        attributes = html_attributes(options)
        attributes.delete(:size) if size_variant(options, TEXTAREA_SIZES)
        attributes[:class] = field_class_name(
          method, "#{textarea_base_class(options)} #{options[:class]}",
          error_class: "textarea-error", options: options
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
        safe_join([ error_message(method, options), help_message(method, options) ].compact)
      end

      def error_message(method, options = {})
        return unless errors?(method, options)

        content_tag(
          :p, full_errors(method, options),
          class: ERROR_MESSAGE_CLASS, id: error_message_id(method)
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

      def field_class_name(method, class_name = "input", error_class: "input-error", options: {})
        return class_name unless errors?(method, options)

        "#{class_name} #{error_class}"
      end

      # A field is in error when the model says so or the caller does. `error:`
      # is the caller's channel (#723): the message rodauth or any other
      # non-ActiveModel validator produced, on a form that may not even have an
      # object. String or Array of them; nil and false both mean "nothing", so
      # `error: rodauth.field_error(param)` can be written unconditionally.
      def errors?(method, options = {})
        explicit_errors(options).any? ||
          (object.respond_to?(:errors) && object.errors.key?(method))
      end

      # The two sources join rather than replace, explicit first — the mirror
      # of the error+help decision above: both are true, so both render, and
      # the caller's message is the more specific one.
      def full_errors(method, options = {})
        safe_join(explicit_errors(options) + model_errors(method), ", ")
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

      # The caller's `error:`, normalized to the array of messages worth
      # rendering. nil disappears on its own; `false` and `""` are dropped by
      # the presence check, which is what lets a call site pass the raw return
      # of its validator without guarding it first.
      def explicit_errors(options)
        Array(options[:error]).select(&:present?)
      end

      def model_errors(method)
        return [] unless object.respond_to?(:errors)

        object.errors.full_messages_for(method)
      end

      # The daisyUI class `size:` names, or nil when the option means the HTML
      # attribute (see INPUT_SIZES). Only Symbols are read as variants —
      # `size: 4` and `size: "4"` keep their attribute meaning untouched — and
      # a Symbol the map does not know raises instead of leaking `size="tiny"`
      # into the markup, the same contract ButtonTaxonomy already enforces for
      # the submit button.
      def size_variant(options, map = INPUT_SIZES)
        size = options[:size]
        return unless size.is_a?(Symbol)

        map.fetch(size) do
          raise ArgumentError,
                "size: #{size.inspect} is not a size variant. " \
                "Valid: #{map.keys.map(&:inspect).join(', ')}. " \
                "An Integer passes through as the HTML size attribute."
        end
      end

      # The variant for a family that takes its element attributes in a second
      # `html:` hash. `size:` reads naturally in either one — next to `label:`,
      # where every other family's variant is written, or inside `html:`, where
      # the HTML attribute of the same name lives — so both are looked at, and
      # a Symbol the map does not know raises from whichever hash it was in.
      #
      # The caller then has to drop `:size` from BOTH hashes: Rails'
      # `select_content_tag` copies `:size` out of the select's own options and
      # onto the element when the element does not already carry one, so
      # stripping the element hash alone still emits `size="sm"`.
      def select_size_variant(options, html_options, map = SELECT_SIZES)
        size_variant(options, map) || size_variant(html_options, map)
      end

      # Add join-item class when addons are present for proper DaisyUI join pattern
      def input_base_class(options)
        has_addons = options[:addon_left].present? || options[:addon_right].present?
        base = has_addons ? INPUT_ADDON_BASE_CLASS : INPUT_BASE_CLASS

        [ base, size_variant(options) ].compact.join(" ")
      end

      def textarea_base_class(options)
        [ TEXTAREA_BASE_CLASS, size_variant(options, TEXTAREA_SIZES) ].compact.join(" ")
      end

      def field_with_addons(field, left:, right:)
        content_tag(:div, class: "join w-full") do
          @template.safe_join([ left, field, right ].compact)
        end
      end
    end
  end
end
