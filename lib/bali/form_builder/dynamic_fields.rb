# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    module DynamicFields
      # TODO: Add tests (Issue: #160)

      # Field helper to add associated records in a form, it generates a label and a link
      # to dynamically add additional associated records.
      #
      #   <%= form_for @product do |f| %>
      #     <%= f.dynamic_fields_group :items,
      #         label: 'Product Items', button_text: 'Add product item' %>
      #     <%= f.submit %>
      #   <% end %>
      #
      # The label and button HTML can be customized by passing a block:
      #
      #   <%= f.dynamic_fields_group :items do %>
      #     <label>Items</label>
      #     <%= f.link_to_add_fields "Add Item", :items %>
      #   <% end %>
      #
      # Requirements:
      # - Partial for the associated fields with the name:
      #     "_#{singular_association_name}_fields.html.erb"
      # - The template needs to have a top level element with the class:
      #     "#{singular_association_name}-fields"
      # - Add "accepts_nested_attributes_for :association, allow_destroy: true"
      # - Allow nested attributes in the controller
      #
      # @param method [Symbol] Name of the association
      # @param options [Hash] options to customize the display
      # @option options [String] :label text for the label tag
      # @option options [String] :button_text for the button to add a new associated record
      def dynamic_fields_group(method, options = {}, &)
        object = self.object
        singular = method.to_s.singularize
        container_id = [object.model_name.singular, singular, 'container'].join('_')

        container = tag.div(id: container_id, data: { 'dynamic-fields-target': 'container' }) do
          safe_join(object.send(method).map do |child_object|
            fields_for method, child_object do |nested_builder|
              @template.render "#{singular}_fields", f: nested_builder, object: object
            end
          end)
        end

        contents = if block_given?
                     @template.capture(&)
                   else
                     default_header_contents(method, options)
                   end

        tag.div(
          data: {
            controller: 'dynamic-fields',
            'dynamic-fields-size-value': object.send(method).size,
            'dynamic-fields-fields-selector-value': ".#{singular}-fields"
          }
        ) do
          safe_join([contents, container].compact)
        end
      end

      def link_to_add_fields(name, association, html_options = {})
        partial = "#{association.to_s.singularize}_fields"

        # When the form.object is a not an ActiveRecord object the nested attributes
        # don't include the sufix "_attributes", so we need to create a new form
        # builder with the original ActiveRecord object to get the same results.
        if object.respond_to?(:original_object)
          object = self.object.original_object
          form_builder = Bulma::FormBuilder.new(object.model_name.param_key, object, @template, {})
        else
          object = self.object
          form_builder = self
        end

        # Render the form fields from a file with the association name provided
        new_object = object.class.reflect_on_association(association).klass.new
        options = { child_index: 'new_record' }
        fields = form_builder.fields_for(association, new_object, options) do |builder|
          @template.render(partial, f: builder, object: object)
        end

        html_options['href'] = '#'
        html_options['data-dynamic-fields-target'] = 'button'
        html_options = prepend_action(html_options, 'dynamic-fields#addFields')

        tag.div(class: html_options.delete(:wrapper_class)) do
          tag.a(name, **html_options) +
            tag.template(fields, data: { 'dynamic-fields-target': 'template' })
        end
      end

      def link_to_remove_fields(name, html_options = {})
        html_options['href'] = '#'
        html_options = prepend_action(html_options, 'dynamic-fields#removeFields')

        remove_type = html_options[:soft_delete] ? :_soft_delete : :_destroy

        tag.a(name, **html_options) +
          hidden_field(remove_type, class: 'destroy-flag')
      end

      private

      def default_header_contents(method, options)
        tag.div(class: 'level') do
          safe_join([
                      label_tag(method, options),
                      add_link_tag(method, options)
                    ])
        end
      end

      def label_tag(method, options)
        translated_label = I18n.t(
          "activerecord.attributes.#{object.model_name.i18n_key}.#{method}"
        )
        label_text = options[:label] || translated_label

        tag.div(class: 'level-left') do
          tag.label(label_text, class: 'label level-item')
        end
      end

      def add_link_tag(method, options)
        button_text = options[:button_text] || 'Add'
        button_class = options[:button_class] || 'button is-primary'

        tag.div(class: 'level-right') do
          link_to_add_fields(
            button_text,
            method,
            { class: button_class, wrapper_class: 'level-item' }
          )
        end
      end
    end
  end
end
