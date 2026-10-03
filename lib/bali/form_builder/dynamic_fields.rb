# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module DynamicFields
      # CSS Classes (DaisyUI + Tailwind)
      HEADER_CLASS = "flex justify-between items-center"
      LABEL_WRAPPER_CLASS = "flex items-center"
      LABEL_CLASS = "label"
      BUTTON_WRAPPER_CLASS = "flex items-center"
      DEFAULT_BUTTON_CLASS = "btn btn-primary"
      DESTROY_FLAG_CLASS = "destroy-flag"
      DEFAULT_TABLE_CLASS = "table"

      # Stimulus Controller
      CONTROLLER_NAME = "dynamic-fields"
      CHILD_INDEX_PLACEHOLDER = "new_record"

      # Field helper to add associated records in a form. Generates a label and link
      # to dynamically add additional associated records.
      #
      # Three shapes of the same anatomy — header, container, `<template>` — that
      # differ only in how row names are built and where the container sits:
      #
      # * default: `fields_for` over an association, names
      #   `movie[characters_attributes][0][name]`.
      # * `table: true`: the container is the `<tbody>` of a table this helper
      #   renders, so the row partial emits `<tr>`. The header and its
      #   `<template>` stay outside the `<table>`, the only place they are valid
      #   — a `<div>` between `<table>` and `<tbody>` is hoisted out of the table
      #   by the HTML parser.
      # * `array: true`: no association and no `fields_for`. Names come out as
      #   `approval_chain[steps][][role]`, for a JSON or array attribute.
      #
      # @example Basic usage
      #   <%= f.dynamic_fields_group :items, label: 'Items', button_text: 'Add item' %>
      #
      # @example Rows as table lines
      #   <%= f.dynamic_fields_group :monetary_lines, table: true,
      #         columns: ['Concept', 'Amount', ''] %>
      #
      # @example An array attribute, no association
      #   <%= f.dynamic_fields_group :steps, array: true, partial: 'step_fields' %>
      #
      # @example With custom block
      #   <%= f.dynamic_fields_group :items do %>
      #     <%= f.link_to_add_fields "Add Item", :items %>
      #   <% end %>
      #
      # @param method [Symbol] Name of the association, or of the array attribute
      # @param options [Hash] Options to customize the display
      # @option options [Boolean] :table Render the container as a `<tbody>`
      # @option options [Array<String>] :columns Header cells, table mode only
      # @option options [String] :table_class Class for the `<table>` element
      # @option options [Boolean] :array Name rows `[][key]`, no `fields_for`
      # @option options [String] :partial Row partial, defaults to `_<singular>_fields`
      # @option options [Array] :values Rows to render, defaults to `object.send(method)`
      def dynamic_fields_group(method, **options, &block)
        singular = method.to_s.singularize
        container = build_fields_container(method, singular, options)
        header = block ? @template.capture(&block) : default_header_contents(method, options)
        body = options[:table] ? wrap_in_table(container, options) : container

        tag.div(data: controller_data_attributes(method, singular, options)) do
          safe_join([ header, body ])
        end
      end

      # Adds a set of nested fields to the form.
      #
      # A `<button>`, not the `<a href="#">` this used to emit. Nothing here
      # navigates, so a screen reader was announcing a link that goes nowhere,
      # and the `#` href jumped the page to the top on any activation the
      # Stimulus action did not swallow.
      #
      # The concrete breakage was `connect()`, which disables this control once
      # the association is at its maximum: `disabled` is inert on an `<a>`, so
      # the cap looked enforced and was not — the control stayed clickable and
      # `addFields` had to bail out on its own. On a `<button>` the attribute
      # does what it says.
      #
      # @param name [String] Button text
      # @param association [Symbol] Association name, or array attribute name
      # @param html_options [Hash] HTML attributes for the button
      # @option html_options [Boolean] :array Build `[][key]` names instead of
      #   reflecting on an association
      # @option html_options [String] :partial Row partial to render
      def link_to_add_fields(name, association, html_options = {})
        partial = html_options[:partial] || "#{association.to_s.singularize}_fields"
        fields = template_fields_for(association, partial, html_options[:array])
        wrapper_class = html_options[:wrapper_class]
        button_options = html_options.except(:wrapper_class, :partial, :array)

        tag.div(class: wrapper_class) do
          tag.button(name, **build_add_link_options(button_options)) +
            tag.template(fields, data: { "#{CONTROLLER_NAME}-target": "template" })
        end
      end

      # Removes a set of nested fields from the form. A `<button>` for the same
      # reason, plus one of its own: these sit inside a `<form>`, where a button
      # with no `type` submits it, so both spell `type="button"` explicitly.
      #
      # @param name [String] Button text
      # @param html_options [Hash] HTML attributes
      # @option html_options [Boolean] :soft_delete Flag `_soft_delete` instead of `_destroy`
      # @option html_options [Boolean] :destroy_flag Pass `false` in array mode: those
      #   rows always leave the DOM on remove, so the flag would only add a
      #   `_destroy` key to the hash the array submits
      def link_to_remove_fields(name, html_options = {})
        destroy_attribute = html_options[:soft_delete] ? :_soft_delete : :_destroy
        button_options = html_options.except(:soft_delete, :destroy_flag)
        button = tag.button(name, **build_remove_link_options(button_options))

        return button if html_options[:destroy_flag] == false

        button + hidden_field(destroy_attribute, class: DESTROY_FLAG_CLASS)
      end

      private

      def build_fields_container(method, singular, options)
        container_id = [ object.model_name.singular, singular, "container" ].join("_")
        container_tag = options[:table] ? :tbody : :div
        partial = options[:partial] || "#{singular}_fields"
        rows = options[:array] ? array_rows(method, partial, options) : association_rows(method, partial)

        tag.public_send(container_tag, id: container_id,
                        data: { "#{CONTROLLER_NAME}-target": "container" }) do
          safe_join(rows)
        end
      end

      def association_rows(method, partial)
        object.send(method).map do |child_object|
          fields_for method, child_object do |nested_builder|
            @template.render partial, f: nested_builder, object: object
          end
        end
      end

      def array_rows(method, partial, options)
        rows_for(method, options).each_with_index.map do |item, index|
          render_array_fields(partial, method, item: item, index: index)
        end
      end

      # `name_prefix` ends in the empty brackets Rails reads as "next element of
      # the array", so the partial names its inputs `#{name_prefix}[role]`.
      #
      # The partial gets the outer builder as `f` — there is no nested object to
      # build one from — so a Bali group takes that name through `name:`, which
      # Rails' `add_default_name_and_id` leaves alone when it is present.
      # `input_name:` reaches every family since #1111 and would work here too;
      # `name:` stays because it is the one spelling that also works when the
      # partial reaches for a plain Rails helper.
      def render_array_fields(partial, method, item:, index:)
        @template.render(partial, f: self, object: object, item: item, index: index,
                                  name_prefix: array_name_prefix(method))
      end

      def array_name_prefix(method)
        "#{object_name}[#{method}][]"
      end

      # `Array.wrap`, not `Array()`: an array attribute holding a single hash
      # would come back as its key/value pairs under the latter.
      def rows_for(method, options)
        return object.send(method) unless options[:array]
        return Array.wrap(options[:values]) if options.key?(:values)
        return [] unless object.respond_to?(method)

        Array.wrap(object.send(method))
      end

      def wrap_in_table(container, options)
        tag.table(class: options[:table_class] || DEFAULT_TABLE_CLASS) do
          safe_join([ table_head(options[:columns]), container ].compact)
        end
      end

      def table_head(columns)
        return nil if columns.blank?

        tag.thead { tag.tr { safe_join(columns.map { |column| tag.th(column) }) } }
      end

      def controller_data_attributes(method, singular, options)
        {
          controller: CONTROLLER_NAME,
          "#{CONTROLLER_NAME}-size-value": rows_for(method, options).size,
          "#{CONTROLLER_NAME}-fields-selector-value": ".#{singular}-fields"
        }
      end

      def default_header_contents(method, options)
        label_text = options[:label] || translate_association_label(method)
        button_text = options[:button_text] || I18n.t("bali_view.form_builder.dynamic_fields.add")
        button_class = options[:button_class] || DEFAULT_BUTTON_CLASS

        tag.div(class: HEADER_CLASS) do
          tag.div(class: LABEL_WRAPPER_CLASS) { tag.label(label_text, class: LABEL_CLASS) } +
            tag.div(class: BUTTON_WRAPPER_CLASS) do
              link_to_add_fields(button_text, method, class: button_class,
                                 array: options[:array], partial: options[:partial])
            end
        end
      end

      def translate_association_label(method)
        I18n.t("activerecord.attributes.#{object.model_name.i18n_key}.#{method}")
      end

      def resolve_form_builder
        if object.respond_to?(:original_object)
          form_object = object.original_object
          [ form_object, Bali::FormBuilder.new(form_object.model_name.param_key,
                                              form_object, @template, {}) ]
        else
          [ object, self ]
        end
      end

      def template_fields_for(association, partial, array)
        return render_array_fields(partial, association, item: nil, index: nil) if array

        form_object, builder = resolve_form_builder
        render_template_fields(builder, association, partial, form_object)
      end

      def render_template_fields(builder, association, partial, form_object)
        new_object = form_object.class.reflect_on_association(association).klass.new
        builder.fields_for(association, new_object,
                           child_index: CHILD_INDEX_PLACEHOLDER) do |nested|
          @template.render(partial, f: nested, object: form_object)
        end
      end

      def build_add_link_options(html_options)
        prepend_action(
          html_options.merge(type: "button", data: { "#{CONTROLLER_NAME}-target": "button" }),
          "#{CONTROLLER_NAME}#addFields"
        )
      end

      def build_remove_link_options(html_options)
        prepend_action(dup_options(html_options).merge(type: "button"),
                       "#{CONTROLLER_NAME}#removeFields")
      end
    end
  end
end
