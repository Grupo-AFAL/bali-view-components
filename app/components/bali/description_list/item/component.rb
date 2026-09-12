# frozen_string_literal: true

module Bali
  module DescriptionList
    module Item
      # One label/value cell inside a `Bali::DescriptionList::Component` grid.
      # Emits `<div><dt/><dd/></div>` — the wrapping `<div>` is what lets a
      # `<dl>` be a grid without the term and its value landing in different
      # cells.
      class Component < ApplicationViewComponent
        BASE_CLASSES = "description-list-item-component"

        # `:horizontal` puts the term and its value side by side inside the
        # cell: `<dt>` on the first track, `<dd>` across the remaining two.
        LAYOUT_CLASSES = {
          stacked: nil,
          horizontal: "grid grid-cols-3 gap-x-2"
        }.freeze

        def initialize(label:, value: nil, layout: :stacked, **options)
          @label = label
          @value = value
          @layout = LAYOUT_CLASSES.key?(layout) ? layout : :stacked
          @options = options
        end

        private

        attr_reader :label, :value, :layout, :options

        def item_classes
          class_names(BASE_CLASSES, LAYOUT_CLASSES[layout], options[:class])
        end

        def item_attributes
          options.except(:class).merge(class: item_classes)
        end

        # LabelValue's typography, so a DescriptionList and a standalone
        # LabelValue on the same page read as one family.
        def label_classes
          Bali::LabelValue::Component::LABEL_CLASSES
        end

        def value_classes
          class_names(
            Bali::LabelValue::Component::VALUE_CLASSES,
            layout == :horizontal && "col-span-2"
          )
        end
      end
    end
  end
end
