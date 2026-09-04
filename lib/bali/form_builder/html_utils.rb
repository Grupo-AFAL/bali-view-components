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

      # The character counter's own class. It lives here rather than next to the
      # textarea because the counter is no longer a textarea feature: `<input>`
      # and `<textarea>` are the same element to the controller, which only reads
      # `value.length` (#723).
      COUNTER_CLASS = "text-base-content/70 text-end w-full"

      # `number_with_commas` keeps its old name — it is the value hosts already
      # pass — but it no longer means "commas". Both separators are read from the
      # active locale at render time, so the same option yields `1,234.56` in
      # English and `1.234,56` wherever the host ships Spanish number formats.
      # The old frozen literal accepted only the English shape, which is what
      # rejected every correctly-typed Spanish amount. `localized_number` is the
      # name that says so.
      PATTERN_TYPES = %i[number_with_commas localized_number].freeze

      # The Stimulus controller that groups thousands as the amount is typed. See
      # `delimited_number_options`.
      NUMBER_FORMAT_CONTROLLER = "number-format"

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
        choose_file_text non_selected_text file_class icon delimited
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

      # The non-model escape hatch of #547: the name and id Rails derives from the
      # form object are the wrong ones when there is no object to derive them from.
      # Reserved, because Bali reads them itself — until #1111 they were absent from
      # this list and honoured by three families only (`select_group`,
      # `slim_select_group` and `block_editor_group`). Everywhere else the key fell
      # through to Rails, which forwards what it does not recognise: `file_group
      # :file, input_name: "import[file]"` painted `input_name="import[file]"` on the
      # input, left the name Rails had derived, and the POST hit
      # `params.require(:import)` and 400'd.
      # `test/bali/form_builder/input_name_option_test.rb` is the list now.
      NON_MODEL_OPTIONS = %i[input_name input_id].freeze

      # The canonical list: every option Bali reads itself. None of them is a
      # valid HTML attribute, and Rails' tag helpers forward whatever they do not
      # recognise straight onto the element — so they all have to be gone before
      # the hash is delegated. Keys that ARE valid attributes (`class`, `type`,
      # `value`, `required`, `placeholder`, `min`, `max`, `step`, `multiple`,
      # `disabled`, `data`...) are deliberately absent, and so are the variant
      # keys a single family reuses under a different meaning (`size` and `color`
      # are daisyUI variants for a checkbox but real attributes on a text input);
      # those are stripped next to the helper that gives them that meaning.
      RESERVED_OPTIONS = (
        WRAPPER_OPTIONS + HELPER_OPTIONS + DATEPICKER_OPTIONS + NON_MODEL_OPTIONS
      ).freeze

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

      # Keys that read like a Bali option, are not one, and are not valid HTML
      # attributes either — so Rails forwarded them onto the element and the thing
      # the call site asked for never happened. Both are measured in #1111.
      #
      # `hint:` is the one Bali itself invited: the docs call the paragraph under a
      # control a "hint" while the option that renders it is `help:`. On the families
      # that build the element's attributes out of the same hash it painted
      # `hint="Formato CSV…"` on the element; on the four that take a second `html:`
      # hash — the three selects and `radio_group` — it was dropped without a trace.
      # Either way the help text was invisible and nothing said so.
      #
      # `input_options:` is v2 muscle memory for "attributes for the element".
      # `file_group :file, input_options: { name: "import[file]" }` emitted
      # `name="file"`, so `params.require(:import)` 400'd and Turbo swallowed the
      # response — a CSV upload screen that did nothing, for weeks, with a green suite.
      #
      # Warned rather than raised, the way #1092 settled it for the editor's moved
      # kwargs: the call site is already broken, and a raise turns a wrong help text
      # into a 500 on upgrade.
      MISTAKEN_OPTIONS = {
        hint: "the help text under a control is `help:`",
        input_options: "attributes for the element are the options themselves, or `html:` " \
                       "on the select, slim_select, time_zone_select and radio families; " \
                       "to override the name or id Rails derives from the form object, " \
                       "`input_name:` / `input_id:`"
      }.freeze

      # The single extraction point. Everything that delegates to Rails goes
      # through here, so no module needs its own `delete`/`except` for the keys
      # above, and none of them can drift out of sync with this list.
      #
      # Returns a new hash every time: the caller's must come back untouched, or
      # reusing one options hash across two fields leaks the first field's
      # classes and Stimulus actions into the second.
      def html_attributes(options)
        warn_mistaken_options(options)
        options.except(*RESERVED_OPTIONS, *MISTAKEN_OPTIONS.keys)
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
        merged = others.compact.each_with_object(options.dup) do |other, acc|
          other.slice(*WRAPPER_OPTIONS).each do |key, value|
            acc[key] = value unless acc.key?(key)
          end
        end

        derive_control_id(merged, others)
      end

      # The other half of the `<label for>` hole #1111 measured on the top-level
      # `id:`. `control_id` reads the group hash, and the group hash is built out of
      # WRAPPER_OPTIONS — which does not include `:id`, and cannot: RESERVED_OPTIONS
      # is built from it, and `html_attributes` would then strip the id off every
      # element in the builder. So on the three families that take a second `html:`
      # hash, `html: { id: "status-select" }` reached the `<select>` and nothing
      # else: the caption went on pointing at Rails' derived `movie_status`, an id
      # not in the document, and the control had no accessible name (WCAG 4.1.2).
      #
      # It is the element hash that wins here, and not the top-level `id:`, because
      # that is the order `apply_input_name_options` resolves them in — `||=` on a
      # key `html_attributes` has already copied over. An explicit `control_id:`
      # still wins over both, including `control_id: false`, which is how a group
      # holding several controls keeps its `<legend>`.
      def derive_control_id(group, others)
        return group if group.key?(:control_id)

        id = others.compact.filter_map { |other| other[:id].presence }.first
        return group unless id

        group.merge(control_id: id)
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
        delimiter = Regexp.escape(number_delimiter)
        separator = Regexp.escape(number_separator)

        "^(\\d+|\\d{1,3}(#{delimiter}\\d{3})*)(#{separator}\\d+)?$"
      end

      def number_delimiter
        I18n.t("number.format.delimiter", default: ",")
      end

      def number_separator
        I18n.t("number.format.separator", default: ".")
      end

      # Mounts `number-format`, which groups the integer digits on every
      # keystroke: an amount reads `1,500,200` as it is typed rather than after a
      # round trip. Until now the delimiter was something the typist had to enter
      # by hand — the field accepted it, and `NumericAttributesWithCommas` parsed
      # it back out, but nobody put it there.
      #
      # Both separators are handed over as values rather than resolved in the
      # browser. `Intl` would read them from the browser's locale while the
      # submitted value is parsed with Rails', so a user on an English browser
      # filling a Spanish form would have had the two halves disagree on which
      # character is the decimal point — which is the bug that concern exists to
      # prevent, one layer up.
      #
      # The two values are assigned rather than prepended. `prepend_values`
      # space-joins onto whatever is already there and then strips, which is
      # exactly right for a token list like `data-action` and silently wrong
      # here: the thousands delimiter is a plain space in several locales — `fr`,
      # `pl`, `sv` — and joining-then-stripping would hand the controller an
      # empty string, turning the grouping off in precisely the locales whose
      # delimiter is hardest to type by hand.
      def delimited_number_options(method, options)
        opts = prepend_controller(dup_options(options), NUMBER_FORMAT_CONTROLLER)

        opts[:data][:"#{NUMBER_FORMAT_CONTROLLER}-delimiter-value"] = number_delimiter
        opts[:data][:"#{NUMBER_FORMAT_CONTROLLER}-separator-value"] = number_separator

        grouped = delimited_number_value(method, opts)
        opts[:value] = grouped unless grouped.nil?
        opts
      end

      # The initial value, grouped here rather than in the browser, because in the
      # browser it is not decidable. `1.500` is a machine number in English and a
      # delimited fifteen hundred in Spanish, where the dot IS the delimiter — one
      # reading submits 1.5, the other 1500, and each corrupts the case it guessed
      # wrong. No amount of pattern-matching on the string settles it; only the
      # object knows.
      #
      # Which is why the test is the *type*, not the shape. A Numeric came from the
      # model. A String is what the typist submitted — `text_field` renders
      # `<attr>_before_type_cast` precisely so a rejected form comes back showing
      # it — and grouping that would delete the characters that made it invalid.
      #
      # Measured on a decimal column: `_before_type_cast` is a Float on a fresh
      # record and after a reload, and a String only on the way back from a failed
      # validation, where the cast value is already wrong (`"1,500,200"` casts to
      # 1). So reading the cast value instead would replace the typist's input
      # with the corruption.
      #
      # nil, not "", when there is nothing to group: `value: nil` would make Rails
      # emit no value attribute at all and wipe the field on re-render.
      def delimited_number_value(method, options)
        return if options.key?(:value)

        raw = raw_attribute_value(method)
        return unless raw.is_a?(Numeric)

        ActiveSupport::NumberHelper.number_to_delimited(
          raw, delimiter: number_delimiter, separator: number_separator
        )
      end

      def raw_attribute_value(method)
        before_type_cast = "#{method}_before_type_cast"
        return unless object.respond_to?(before_type_cast)

        object.public_send(before_type_cast)
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

        counter_attributes(attributes) if char_counter?(options)
        apply_input_name_options(options, attributes)

        merge_aria_attributes(attributes, method, options)
      end

      def textarea_field_options(method, options)
        attributes = html_attributes(options)
        attributes.delete(:size) if size_variant(options, TEXTAREA_SIZES)
        attributes[:class] = field_class_name(
          method, "#{textarea_base_class(options)} #{options[:class]}",
          error_class: "textarea-error", options: options
        )

        counter_attributes(attributes) if stimulus_counter?(options)
        apply_input_name_options(options, attributes)

        merge_aria_attributes(attributes, method, options)
      end

      # Escape hatch for non-model forms (issue #547): `input_name:` / `input_id:`
      # in the options hash override the name/id Rails derives from the form
      # object. Explicit `name:` / `id:` in html_options still win.
      #
      # Called by every family whose control is a native named input. Before #1111 it
      # had two callers — `select_field` and `slim_select_field` — which is what made
      # the option a trap everywhere else; see NON_MODEL_OPTIONS. The families that
      # do NOT call it are named, with the reason each cannot, in
      # `test/bali/form_builder/input_name_option_test.rb`.
      #
      # Plain `name:` and `id:` are promoted the same way, which only does anything
      # on the families that take a second `html:` hash. On the other ten the two
      # hashes are one, so `html_attributes` has already put both on the element and
      # the `||=` is a no-op. On the select three it was a real hole: a top-level
      # `name:` was handed to Rails' `select` as a field option, which does not read
      # it, and vanished — and a top-level `id:` vanished the same way while
      # `control_id` went on pointing the caption's `for` at it, so the `<label for>`
      # named an element that was not in the document and the control had no
      # accessible name at all. Measured on `select_group`, `slim_select_group` and
      # `time_zone_select_group` (#1111).
      def apply_input_name_options(options, html_options)
        name = options[:input_name] || options[:name]
        id = options[:input_id] || options[:id]

        html_options[:name] ||= array_name(name, options, html_options) if name
        html_options[:id] ||= id if id
        html_options
      end

      # `multiple` is what makes a control submit a list, and Rails spells that in
      # the name — but only in a name it derived itself. `add_default_name_and_id`
      # is `options["name"] = options.fetch("name") { tag_name(multiple, index) }`,
      # so the `[]` is inside the block and a name this hatch supplies never gets
      # one. `file_group :documents, multiple: true, input_name: "import[documents]"`
      # then submitted three chosen files under one un-suffixed key, Rack kept the
      # last, and `params[:import][:documents]` was a file instead of an array —
      # silently, which is the shape of failure #1111 is about. Measured on
      # `file_group` and `select_group` (#1113).
      #
      # A name already ending in `[]` is left alone, so writing the suffix by hand
      # keeps working and never doubles.
      def array_name(name, options, html_options)
        return name unless multiple_control?(options, html_options)
        return name if name.to_s.end_with?("[]")

        "#{name}[]"
      end

      # Whether the element this name lands on will really be `multiple` — which is
      # not the same question as "did the caller write `multiple:` somewhere".
      #
      # It is Rails' own rule, copied for the reason it exists: `select_content_tag`
      # moves `:multiple` out of the field options onto the element only when the
      # element does not already carry the key, so `html:` wins over the top level.
      # SlimSelect's `<select>` always carries the key — `build_html_options` seeds it
      # so its own widget can read it — and until #1123 it seeded a flat `false`, which
      # blocked the copy and left a top-level `multiple: true` off the element for
      # good; it now seeds through this same method, so the element and the name are
      # decided by one rule. Reading "either hash" here instead would suffix the name
      # of a select that `html: { multiple: false }` keeps single-valued, which is the
      # same silent mis-submission the other way round: `params[:import][:tags]` an
      # array of one where the form sends a value.
      def multiple_control?(options, html_options)
        if html_options.key?(:multiple) || html_options.key?("multiple")
          return html_options[:multiple] || html_options["multiple"]
        end

        options[:multiple] || options["multiple"]
      end

      def field_helper(method, field, options = {})
        warn_mistaken_options(options)
        messages = error_and_help(method, options)

        left_addon = options[:addon_left]
        right_addon = options[:addon_right]
        addons = left_addon.present? || right_addon.present?
        control = addons ? field_with_addons(field, left: left_addon, right: right_addon) : field

        # When addons exist, don't wrap in control div - use join pattern directly.
        # A counter is the exception: it has to live inside the element carrying
        # the controller, so the join goes in the control div with it.
        return control + messages if addons && !char_counter?(options)

        control_class = [ "control", options[:control_class] ].compact.join(" ")
        wrapped_field = content_tag(
          :div, safe_join([ control, counter_element(options) ].compact),
          class: control_class, data: control_data(options)
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

      # Two funnels, because a mistaken key can be in either hash a helper takes:
      # `html_attributes` sees the one on its way to the element (where `hint="…"`
      # was landing), `field_helper` sees the group's own — which is the only one
      # `radio_group` and the three select families ever put it in. The families
      # that reach neither call this directly; `block_editor_field` is the one.
      #
      # One warning per key per builder, not per field: a form repeating the same
      # typo on six inputs has one thing wrong with it, and six identical lines is
      # how a log gets skimmed. The guard is also what keeps a single field going
      # through both funnels from warning twice.
      def warn_mistaken_options(options)
        return unless options.is_a?(Hash)

        @warned_mistaken_options ||= []

        MISTAKEN_OPTIONS.each do |key, correction|
          next unless options.key?(key)
          next if @warned_mistaken_options.include?(key)

          @warned_mistaken_options << key
          Bali.deprecator.warn(
            "Bali::FormBuilder: `#{key}:` is not an option, so it was ignored — #{correction}."
          )
        end
      end

      # The `data` of the `.control` div. It is the caller's own `control_data:`
      # until a counter or auto-grow is asked for, and then it is also where the
      # `textarea` controller and its values are declared — the controller has to
      # sit on an element that contains both the control and the counter, and the
      # control div is the only one that does.
      def control_data(options)
        return options[:control_data] unless stimulus_counter?(options)

        counter = options[:char_counter]
        max_length = counter.is_a?(Hash) ? counter[:max] : 0

        (options[:control_data] || {}).merge(
          controller: "textarea",
          'textarea-max-length-value': max_length,
          'textarea-auto-grow-value': options[:auto_grow].present?
        )
      end

      # The pair of attributes that make a control the counter's subject. Both
      # families hand them to the element they render — a `<textarea>` and an
      # `<input>` are the same thing to the controller, which only reads
      # `value.length`.
      #
      # `prepend_action` and not `merge`: a call site that already wired its own
      # `data: { action: }` keeps it, with this one added in front.
      #
      # The `:data` hash is copied first because those two helpers mutate in
      # place, and `html_attributes` hands back the caller's very object under
      # that key — writing through it is how one field ends up carrying the
      # previous field's Stimulus wiring. Same reason `dup_options` exists.
      def counter_attributes(attributes)
        attributes[:data] = attributes[:data].dup if attributes[:data].is_a?(Hash)

        prepend_action(
          prepend_data_attribute(attributes, :'textarea-target', "input"),
          "input->textarea#onInput"
        )
      end

      def char_counter?(options)
        options[:char_counter].present?
      end

      # Auto-grow is a textarea's own option and does not imply a counter, but it
      # needs the same controller on the same wrapper.
      def stimulus_counter?(options)
        char_counter?(options) || options[:auto_grow].present?
      end

      # Not `fieldset-label` like the help and error messages: that class is a
      # flex container, and the counter needs `text-end` on a block to sit on the
      # right. It inherits the fieldset's small type the way it always did.
      def counter_element(options)
        return unless char_counter?(options)

        content_tag(:p, "", class: COUNTER_CLASS, data: { 'textarea-target': "counter" })
      end

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
