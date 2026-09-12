# frozen_string_literal: true

module Bali
  module LabelValue
    # One read-only field: a term and the value that answers it.
    #
    # Rendered as a single-pair `<dl>`. The `<label>` this used to emit had no
    # control to point at, which makes it a label for nothing — screen readers
    # read the text but never tie it to the value beside it. `<dt>`/`<dd>` is
    # the pairing the markup actually means, and it survives with no ARIA.
    #
    # Reach for `Bali::PropertiesTable::Component` instead when the pairs form
    # one set read top to bottom: it renders a single `<table>` of `<th
    # scope="row">`/`<td>` rows, which gives a screen reader table navigation
    # over the whole set and one announcement of how many rows there are.
    # Reach for `Bali::DescriptionList::Component` when the pairs form one set
    # that wants a grid rather than table rows: ONE `<dl>` with a cell per
    # pair, so the whole set stays a single list announced once.
    # LabelValue is the right call for a pair that stands on its own, or when
    # each pair needs its own placement in a layout neither of those can
    # express — every instance is its own one-pair list, so a run of them is
    # a run of lists, not one set.
    class Component < ApplicationViewComponent
      LABEL_CLASSES = "font-bold text-xs text-base-content/70"
      VALUE_CLASSES = "min-h-6"

      attr_reader :label, :value

      def initialize(label:, value: nil, **options)
        @label = label
        @value = value
        @options = options
      end

      private

      attr_reader :options

      def component_classes
        class_names("mb-2", options[:class])
      end

      def component_attributes
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
