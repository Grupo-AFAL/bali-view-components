# frozen_string_literal: true

module Bali
  module FieldGroupWrapper
    class Component < ApplicationViewComponent
      # DaisyUI 5 uses fieldset pattern for form groups
      BASE_CLASSES = "fieldset w-full"
      LEGEND_CLASSES = "fieldset-legend"
      LEGEND_TEXT_CLASSES = "flex items-center gap-2"

      # A `<legend>` names the `<fieldset>`, not the control inside it, so for a
      # group holding one input it named nothing a screen reader would read out:
      # every `*_field_group` was an unnamed control (WCAG 1.3.1, 4.1.2). The
      # caption is therefore a `<label for>` whenever there is a single control
      # to point it at, and stays a `<legend>` only where the group really holds
      # several controls that already carry labels of their own — a radio list, a
      # checkbox, a composite widget. `.fieldset-legend` is a plain class in
      # daisyUI 5 with no element in the selector, so both render identically.
      #
      # `:control_id` names the control the caption points at. Absent — the case
      # for the ~18 families that wrap exactly one labelable control, and for a
      # host rendering this component directly — the id is derived the same way
      # the field helper derives the input's. `false` keeps the `<legend>`, for a
      # group that really holds several controls or a widget no `for` can reach.
      #
      # It travels in `options` rather than as a keyword argument on purpose:
      # the last parameter is a positional Hash, so any keyword here would
      # swallow `label:`, `class:` and `type:` out of every existing call site.
      def initialize(form, method, options = {})
        @form = form
        @method = method
        @label_options = normalize_label_options(options[:label])
        @field_class = options[:field_class]
        @field_data = options[:field_data]
        @type = options[:type]
        @custom_class = options[:class]
        @control_id = resolve_control_id(form, method, options)
      end

      def call
        tag.fieldset(id: field_id, class: wrapper_classes, data: @field_data) do
          safe_join([ legend_html, content ].compact)
        end
      end

      private

      attr_reader :form, :method, :label_options, :field_class, :field_data, :type, :control_id

      # Derived with Rails' own `field_id`, so it follows the same namespace,
      # index and nested-attribute rules as the control and the error/help
      # paragraphs. The old `field-#{method}` ignored all three, so two forms
      # for the same model on one page emitted the same id twice.
      def field_id
        @form.field_id(@method, "field")
      end

      def wrapper_classes
        class_names(BASE_CLASSES, @field_class, @custom_class)
      end

      def legend_html
        return if hidden_field? || label_disabled?
        return simple_legend if @label_options[:tooltip].blank?

        legend_with_tooltip
      end

      def simple_legend
        caption_tag(class: LEGEND_CLASSES) { label_text }
      end

      def legend_with_tooltip
        caption_tag(class: legend_classes) do
          tag.span(class: LEGEND_TEXT_CLASSES) do
            safe_join([ label_text, tooltip_icon ])
          end
        end
      end

      # The caption always carries an id, whichever element it turns out to be:
      # a widget that no `for` can reach — `<trix-editor>` is not a labelable
      # element — still has something to point an `aria-labelledby` at, and it
      # derives that id from `field_id` rather than being handed it.
      def caption_tag(**attributes, &block)
        attributes[:id] = @form.label_id(@method)
        return tag.legend(**attributes, &block) unless control_id.present?

        tag.label(**attributes, for: control_id, &block)
      end

      def label_text
        @label_options[:text] || @form.translate_attribute(@method)
      end

      # Through Bali::HelpTip (#993), so the help icon on a form field and the
      # one a host renders next to a table header are the same component — this
      # used to build the Tooltip+Icon pair privately, and hosts rewrote it.
      def tooltip_icon
        render(Bali::HelpTip::Component.new(@label_options[:tooltip]))
      end

      def legend_classes
        class_names(LEGEND_CLASSES, @label_options[:class])
      end

      def hidden_field?
        @type.to_s == "hidden"
      end

      def label_disabled?
        @label_options[:text] == false
      end

      def resolve_control_id(form, method, options)
        explicit = options[:control_id]
        return explicit unless explicit.nil?

        form.control_id(method, options)
      end

      def normalize_label_options(label)
        case label
        when Hash then label
        when nil then {}
        else { text: label }
        end
      end
    end
  end
end
