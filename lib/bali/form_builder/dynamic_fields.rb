# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module DynamicFields
      # CSS Classes (DaisyUI + Tailwind)
      HEADER_CLASS = 'flex justify-between items-center'
      LABEL_WRAPPER_CLASS = 'flex items-center'
      LABEL_CLASS = 'label'
      BUTTON_WRAPPER_CLASS = 'flex items-center'
      DEFAULT_BUTTON_CLASS = 'btn btn-primary'
      DESTROY_FLAG_CLASS = 'destroy-flag'

      # Stimulus Controller
      CONTROLLER_NAME = 'dynamic-fields'
      CHILD_INDEX_PLACEHOLDER = 'new_record'

      # Field helper to add associated records in a form. Generates a label and link
      # to dynamically add additional associated records.
      #
      # @example Basic usage
      #   <%= f.dynamic_fields_group :items, label: 'Items', button_text: 'Add item' %>
      #
      # @example With custom block
      #   <%= f.dynamic_fields_group :items do %>
      #     <%= f.link_to_add_fields "Add Item", :items %>
      #   <% end %>
      #
      # @param method [Symbol] Name of the association
      # @param options [Hash] Options to customize the display
      def dynamic_fields_group(method, options = {}, &block)
        singular = method.to_s.singularize
        container = build_fields_container(method, singular)
        header = block ? @template.capture(&block) : default_header_contents(method, options)

        tag.div(data: controller_data_attributes(method, singular)) do
          safe_join([header, container])
        end
      end

      # Creates a link to add new nested fields
      # @param name [String] Link text
      # @param association [Symbol] Association name
      # @param html_options [Hash] HTML attributes for the link
      def link_to_add_fields(name, association, html_options = {})
        partial = "#{association.to_s.singularize}_fields"
        form_object, builder = resolve_form_builder
        fields = render_template_fields(builder, association, partial, form_object)
        wrapper_class = html_options.delete(:wrapper_class)

        tag.div(class: wrapper_class) do
          tag.a(name, **build_add_link_options(html_options)) +
            tag.template(fields, data: { "#{CONTROLLER_NAME}-target": 'template' })
        end
      end

      # Creates a link to remove nested fields
      # @param name [String] Link text
      # @param html_options [Hash] HTML attributes (:soft_delete for soft delete)
      def link_to_remove_fields(name, html_options = {})
        soft_delete = html_options.delete(:soft_delete)
        destroy_attribute = soft_delete ? :_soft_delete : :_destroy

        tag.a(name, **build_remove_link_options(html_options)) +
          hidden_field(destroy_attribute, class: DESTROY_FLAG_CLASS)
      end

      private

      def build_fields_container(method, singular)
        container_id = [object.model_name.singular, singular, 'container'].join('_')

        tag.div(id: container_id, data: { "#{CONTROLLER_NAME}-target": 'container' }) do
          safe_join(object.send(method).map do |child_object|
            fields_for method, child_object do |nested_builder|
              @template.render "#{singular}_fields", f: nested_builder, object: object
            end
          end)
        end
      end

      def controller_data_attributes(method, singular)
        {
          controller: CONTROLLER_NAME,
          "#{CONTROLLER_NAME}-size-value": object.send(method).size,
          "#{CONTROLLER_NAME}-fields-selector-value": ".#{singular}-fields"
        }
      end

      def default_header_contents(method, options)
        label_text = options[:label] || translate_association_label(method)
        button_text = options[:button_text] || I18n.t('helpers.add.text')
        button_class = options[:button_class] || DEFAULT_BUTTON_CLASS

        tag.div(class: HEADER_CLASS) do
          tag.div(class: LABEL_WRAPPER_CLASS) { tag.label(label_text, class: LABEL_CLASS) } +
            tag.div(class: BUTTON_WRAPPER_CLASS) do
              link_to_add_fields(button_text, method, class: button_class)
            end
        end
      end

      def translate_association_label(method)
        I18n.t("activerecord.attributes.#{object.model_name.i18n_key}.#{method}")
      end

      def resolve_form_builder
        if object.respond_to?(:original_object)
          form_object = object.original_object
          [form_object, Bali::FormBuilder.new(form_object.model_name.param_key,
                                              form_object, @template, {})]
        else
          [object, self]
        end
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
          html_options.merge(href: '#', data: { "#{CONTROLLER_NAME}-target": 'button' }),
          "#{CONTROLLER_NAME}#addFields"
        )
      end

      def build_remove_link_options(html_options)
        prepend_action(html_options.merge(href: '#'), "#{CONTROLLER_NAME}#removeFields")
      end
    end
  end
end
