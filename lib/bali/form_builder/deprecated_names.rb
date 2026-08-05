# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # One release cycle of compatibility for the spellings v3 replaced, and the
    # only place any of them survives. Everything here is removed in 4.0.
    #
    # Which old names got a shim was measured, not guessed. The eight
    # applications that render this builder — afal-apps, ga-apps,
    # gobierno-corporativo, centinela-web, costa-norte, identity, opina and
    # bali-auth — were counted call site by call site, and a name is shimmed if
    # any of them calls it. Eighteen do; the seven renamed helpers nobody calls
    # (`coordinates_polygon_field_group`, `direct_upload_field_group`,
    # `numeric_field_group`, `recurrent_event_rule_field_group`,
    # `step_number_field_group`, `time_period_field_group` and the
    # `datetime_select_group` alias) raise `NoMethodError` instead, which is the
    # cheapest possible signal for a name with no traffic to protect.
    module DeprecatedNames
      # Old name => new name, for the families whose only parameter was the
      # options hash. Ordered by measured call sites across those eight apps, so
      # the cost of the rename is legible from the source.
      RENAMED_OPTION_GROUPS = {
        text_field_group: :text_group,               # 329
        number_field_group: :number_group,           #  88
        date_field_group: :date_group,               #  57
        file_field_group: :file_group,               #  49
        time_field_group: :time_group,               #  19
        email_field_group: :email_group,             #  14
        currency_field_group: :currency_group,       #  12
        date_select_group: :date_group,              #   7
        password_field_group: :password_group,       #   7
        datetime_field_group: :datetime_group,       #   6
        url_field_group: :url_group,                 #   4
        percentage_field_group: :percentage_group,   #   4
        month_field_group: :month_group              #   2
      }.freeze

      # The two families that also took `checked_value` / `unchecked_value` as
      # trailing positional arguments.
      RENAMED_CHECKED_GROUPS = {
        boolean_field_group: :boolean_group,         #  50
        check_box_group: :boolean_group,             #   3
        switch_field_group: :switch_group            #   6
      }.freeze

      RENAMED_OPTION_GROUPS.each do |old_name, new_name|
        define_method(old_name) do |method, options = {}, &block|
          deprecated_helper_name(old_name, new_name)
          public_send(new_name, method, **options, &block)
        end
      end

      RENAMED_CHECKED_GROUPS.each do |old_name, new_name|
        define_method(old_name) do |method, options = {}, checked = "1", unchecked = "0"|
          deprecated_helper_name(old_name, new_name)
          public_send(
            new_name, method, checked_value: checked, unchecked_value: unchecked, **options
          )
        end
      end

      # 270 call sites across those eight applications — after `text_group` the
      # busiest helper in the builder, and the only one outside the field
      # families that carried a name of its own. What it renders is exactly what
      # every `<type>_group` renders: the control inside its wrapper.
      def submit_actions(value, options = {})
        deprecated_helper_name(:submit_actions, :submit_group)
        submit_group(value, **options)
      end

      # 11 call sites. The only renamed family that took a second positional
      # hash, so it is also the only one whose shim has to move that hash onto
      # `html:` on the way through.
      def radio_field_group(method, values, options = {}, html_options = {})
        deprecated_helper_name(:radio_field_group, :radio_group)
        radio_group(method, values, html: html_options, **options)
      end

      # The three select families kept their names and changed their call shape,
      # which for a host is the same kind of break as a rename — and they are the
      # busiest surface in the builder, at 399 measured call sites for
      # `select_group` and `slim_select_group` alone. 28 of those pass the v2
      # positional hashes, so the pair is accepted for one cycle rather than
      # turned into an `ArgumentError` on upgrade.
      #
      # Returns the `[options, html]` pair the helper would have received had it
      # been called the new way. The three shapes v2 allowed:
      #
      #   (values, opts)              -> opts are the field's own options
      #   (values, opts, html_opts)   -> the full positional pair
      #   (values, opts, key: value)  -> trailing keywords WERE the html hash
      #
      # The third is why the keywords cannot simply be kept as the options: in
      # v2 they landed on the element, and reading them as field options would
      # move `class:` and `multiple:` off the `<select>` without saying so.
      def legacy_option_hashes(name, legacy, html, options)
        return [ options, html ] if legacy.empty?

        deprecated_positional_hashes(name)

        return [ legacy.first.to_h, options.presence || html ] if legacy.one?

        [ legacy.first.to_h, legacy.second.to_h ]
      end

      private

      def deprecated_helper_name(old_name, new_name)
        Bali.deprecator.warn(
          "Bali::FormBuilder##{old_name} is deprecated. Use ##{new_name}, which takes " \
          "keywords: every field helper is now `<type>_group` for the wrapped control " \
          "and `<type>_field` for the bare one."
        )
      end

      def deprecated_positional_hashes(name)
        Bali.deprecator.warn(
          "Bali::FormBuilder##{name} no longer takes positional option hashes. Pass the " \
          "field's own options as keywords and the element's attributes as `html:`."
        )
      end
    end
  end
end
