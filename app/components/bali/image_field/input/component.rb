# frozen_string_literal: true

module Bali
  module ImageField
    module Input
      class Component < ApplicationViewComponent
        include Bali::DeprecatedIconName

        DEFAULT_FORMATS = %i[jpg jpeg png webp].freeze
        DEFAULT_ICON = "camera"
        private_constant :DEFAULT_FORMATS, :DEFAULT_ICON

        attr_reader :form, :field_name, :icon

        # The only one of the seven receivers whose `icon:` has a default, so here the
        # deprecated spelling is read first: `icon:` is always set, and reading it first
        # would make `icon_name:` unreachable rather than deprecated.
        #
        # @param icon [String, Symbol] Icon name drawn over the image on hover.
        # @param icon_name [String, nil] @deprecated Removed in Bali 4.0. Use `icon:`.
        def initialize(form:, method:, formats: DEFAULT_FORMATS, icon: DEFAULT_ICON,
                       icon_name: nil, **options)
          @form = form
          @field_name = method
          @formats = formats.freeze
          @icon = deprecated_icon_name(icon_name) || icon
          @options = options
        end

        private

        attr_reader :formats, :options

        def container_classes
          class_names(
            "image-input-container",
            "absolute inset-0 flex justify-center items-center cursor-pointer",
            "rounded-lg",
            "group-hover:bg-base-content/20 group-hover:backdrop-blur-sm",
            "max-md:bg-base-content/20 max-md:backdrop-blur-sm"
          )
        end

        def icon_wrapper_classes
          class_names(
            "hidden",
            "group-hover:flex max-md:flex"
          )
        end

        def input_options
          opts = options.dup
          opts[:accept] = accepted_formats
          opts[:class] = class_names("hidden", options[:class])
          prepend_data_attribute(
            prepend_action(opts, "change->image-field#show"),
            "image-field-target",
            "input"
          )
        end

        def accepted_formats
          formats.map { |f| ".#{f}" }.join(", ")
        end

        # Use raw Rails file_field to avoid Bali::FormBuilder's custom wrapper
        def raw_file_field
          if form.respond_to?(:rails_file_field)
            form.rails_file_field(field_name, **input_options)
          else
            form.file_field(field_name, **input_options)
          end
        end
      end
    end
  end
end
