# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module SelectFields
      # DaisyUI base classes for select elements
      BASE_CLASSES = "select select-bordered w-full"

      # `**options` are the field's own — what Rails' `select` reads
      # (`include_blank:`, `prompt:`, `selected:`) plus what the group reads
      # (`label:`, `help:`). `html:` is what lands on the `<select>` element.
      # That is the same split v2 had; it was just spelled as two anonymous
      # positional hashes nobody could tell apart at the call site.
      def select_group(method, values, *legacy, html: {}, **options)
        options, html = legacy_option_hashes(:select_group, legacy, html, options)
        group = group_options(options, html)

        @template.render Bali::FieldGroupWrapper::Component.new(self, method, group) do
          select_field(method, values, html: html, **options)
        end
      end

      # Uses the native HTML <select> element with DaisyUI styling.
      def select_field(method, values, *legacy, html: {}, **options)
        options, html_options = legacy_option_hashes(:select_field, legacy, html, options)
        group = group_options(options, html_options)
        variant = select_size_variant(options, html_options)
        options = options.except(:size) if variant

        attributes = html_attributes(html_options)
        attributes.delete(:size) if variant
        attributes[:class] = select_classes(method, group, html_options[:class], variant)
        apply_input_name_options(options, attributes)
        merge_aria_attributes(attributes, method, group)

        field = select(method, values, options, attributes)
        field_helper(method, field, group)
      end

      private

      # `options` is the merged group hash — `error:` may arrive top-level or in
      # `html:`, and `group_options` has already read both.
      def select_classes(method, options, additional_classes = nil, variant = nil)
        base = field_class_name(method, [ BASE_CLASSES, variant ].compact.join(" "),
                                        error_class: "select-error", options: options)
        # `input_class:` is read off the group hash, which is where a top-level
        # option lands on the four families that take a second `html:` hash.
        # `html: { class: }` is the older spelling and still the one this family
        # documents; both reach the `<select>` and both are asserted in
        # `input_class_option_test.rb`.
        @template.token_list(base, additional_classes, options[:input_class])
      end
    end
  end
end
