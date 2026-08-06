# frozen_string_literal: true

module Bali
  class FormBuilder < ActionView::Helpers::FormBuilder
    # El de Rails, para que la implementación pueda vivir bajo el nombre canónico
    # `time_zone_select_field`. Se liga por la superclase y no con `alias`: ver la nota larga
    # en `file_fields.rb` (#840).
    define_method(:rails_time_zone_select, superclass.instance_method(:time_zone_select))

    module TimeZoneSelectFields
      # DaisyUI select classes matching SelectFields pattern
      BASE_CLASSES = "select select-bordered w-full"

      def time_zone_select_group(method, priority_zones = nil, *legacy, html: {}, **options)
        options, html = legacy_option_hashes(:time_zone_select_group, legacy, html, options)
        group = group_options(options, html)

        @template.render(Bali::FieldGroupWrapper::Component.new(self, method, group)) do
          time_zone_select_field(method, priority_zones, html: html, **options)
        end
      end

      # Rails' own name, kept as an override so an existing `f.time_zone_select`
      # keeps its daisyUI classes and its error and help messages.
      def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
        time_zone_select_field(method, priority_zones, html: html_options, **options)
      end

      def time_zone_select_field(method, priority_zones = nil, *legacy, html: {}, **options)
        options, html = legacy_option_hashes(:time_zone_select_field, legacy, html, options)
        group = group_options(options, html)
        variant = select_size_variant(options, html)
        options = options.except(:size) if variant
        attributes = time_zone_html_options(method, html, group, variant)
        field = rails_time_zone_select(method, priority_zones, options, attributes)

        field_helper(method, field, group)
      end

      private

      # `group` and not `html`: `aria_attributes` decides whether to emit
      # `aria-describedby` by looking for `help:`, so reading the hash that does
      # not carry it points the control at nothing while the paragraph renders
      # anyway — a description that exists on screen and not in the a11y tree.
      def time_zone_html_options(method, html_options, group = html_options, variant = nil)
        base = field_class_name(method, [ BASE_CLASSES, variant ].compact.join(" "),
                                        error_class: "select-error", options: group)

        attributes = html_attributes(html_options).except(:class).merge(
          class: [ base, html_options[:class] ].compact.join(" ")
        )
        attributes.delete(:size) if variant

        merge_aria_attributes(attributes, method, group)
      end
    end
  end
end
