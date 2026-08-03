# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # Se liga el método de la SUPERCLASE por su dueño, no `alias file_field`.
    #
    # `alias` captura lo que el nombre resuelva EN ESE MOMENTO. La primera vez que se carga
    # este archivo `FileFields` todavía no está incluido, así que captura el de ActionView y
    # todo funciona. Pero el archivo se vuelve a ejecutar en cada reload de código, y para
    # entonces el módulo YA está incluido: el alias pasaba a apuntar al override de Bali, y
    # `rails_file_field` terminaba llamándose a sí mismo. Cualquier host en desarrollo se
    # comía un `SystemStackError` en todos sus file fields desde el primer reload y hasta
    # reiniciar el servidor (#840). Ningún test lo agarraba porque la suite arranca en frío.
    #
    # `instance_method` sobre la superclase no depende del orden de carga ni de cuántas veces
    # se re-ejecute el archivo: sólo puede significar el de Rails.
    define_method(:rails_file_field, superclass.instance_method(:file_field))

    module FileFields
      # hidden class hides the native file input (consistent with ImageField)
      INPUT_CLASS = "hidden"
      WRAPPER_CLASS = "flex items-center gap-3"
      FILENAME_CLASS = "text-sm text-base-content/60 truncate"
      CTA_CLASS = "btn btn-soft btn-primary btn-sm gap-2"
      LABEL_CLASS = "cursor-pointer inline-flex"
      DEFAULT_ICON = "upload"

      def file_group(method, **options)
        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, options)) do
          file_field(method, options)
        end
      end

      def file_field(method, options = {})
        field_helper(method, custom_file_field(method, options), options)
      end

      private

      def custom_file_field(method, options = {})
        choose_file_text = options.fetch(:choose_file_text) { default_choose_text }
        non_selected_text = options.fetch(:non_selected_text) { default_non_selected_text }
        file_icon_name = options[:icon] || DEFAULT_ICON
        multiple = options.fetch(:multiple, false)
        file_class = options[:file_class]

        input_options = build_file_input_options(field_options(method, options))

        @template.content_tag(:div, wrapper_options(non_selected_text, multiple, file_class)) do
          file_label(method, input_options, file_icon_name, choose_file_text) +
            filename_display(non_selected_text)
        end
      end

      def file_label(method, input_options, file_icon_name, choose_file_text)
        @template.content_tag(:label, class: LABEL_CLASS) do
          rails_file_field(method, input_options) +
            file_cta(file_icon_name, choose_file_text)
        end
      end

      def build_file_input_options(options)
        # Override class completely - file input must be hidden (not styled as DaisyUI input)
        opts = dup_options(options).merge(class: INPUT_CLASS)
        opts = prepend_action(opts, "file-input#onChange")
        prepend_data_attribute(opts, :file_input_target, :input)
      end

      def wrapper_options(non_selected_text, multiple, file_class)
        {
          class: class_names(WRAPPER_CLASS, file_class => file_class.present?),
          data: {
            controller: "file-input",
            file_input_non_selected_text_value: non_selected_text,
            file_input_multiple_value: multiple
          }
        }
      end

      def filename_display(non_selected_text)
        @template.content_tag(
          :span,
          non_selected_text,
          class: FILENAME_CLASS,
          data: { 'file-input-target': "value" }
        )
      end

      def file_cta(icon_name, label_text)
        @template.content_tag(:span, class: CTA_CLASS) do
          icon = @template.render(Bali::Icon::Component.new(icon_name))
          label = label_text && @template.content_tag(:span, label_text)
          icon + (label || "".html_safe)
        end
      end

      def default_choose_text
        I18n.t("bali_view.form_builder.file.choose_file")
      end

      def default_non_selected_text
        I18n.t("bali_view.form_builder.file.no_file_selected")
      end
    end
  end
end
