# frozen_string_literal: true

module Bali
  module DescriptionList
    # A set of read-only label/value pairs laid out in the component's own
    # responsive grid — one `<dl>` whose items are `<div><dt/><dd/></div>`
    # cells (a `<div>` wrapping `<dt>`/`<dd>` inside a `<dl>` is valid HTML).
    #
    # This is the middle ground between `Bali::LabelValue::Component` (ONE
    # pair, placed by the caller) and `Bali::PropertiesTable::Component` (one
    # set read straight through with table navigation). Reach for
    # DescriptionList when the pairs belong together as a set but want a grid
    # rather than table rows. `<dt>`/`<dd>` reuse LabelValue's typography so
    # the three options read as one family.
    class Component < ApplicationViewComponent
      BASE_CLASSES = "description-list-component grid gap-x-6 gap-y-3"

      # Frozen hash so Tailwind sees the responsive classes as literal strings
      # in a scanned file — same pattern as
      # `Bali::DashboardPage::Component::STATS_COLUMNS`.
      COLUMNS = {
        1 => "grid-cols-1",
        2 => "grid-cols-1 sm:grid-cols-2",
        3 => "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
      }.freeze

      DEFAULT_COLUMNS = 2

      renders_many :items, lambda { |label:, value: nil, **options|
        Bali::DescriptionList::Item::Component.new(
          label: label, value: value, layout: @layout, **options
        )
      }

      def initialize(columns: DEFAULT_COLUMNS, layout: :stacked, **options)
        @columns = columns
        @layout = layout
        @options = options
      end

      private

      attr_reader :options

      def component_classes
        class_names(BASE_CLASSES, COLUMNS.fetch(@columns, COLUMNS[DEFAULT_COLUMNS]), options[:class])
      end

      def component_attributes
        options.except(:class).merge(class: component_classes)
      end
    end
  end
end
