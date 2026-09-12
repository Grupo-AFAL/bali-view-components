# frozen_string_literal: true

module Bali
  module DescriptionList
    class Preview < ApplicationViewComponentPreview
      # DescriptionList lays out a SET of label/value pairs in its own responsive
      # grid. For a single pair you place yourself use `Bali::LabelValue`; when
      # the set reads top to bottom like a table, use `Bali::PropertiesTable`.
      #
      # `layout: :horizontal` puts each term and its value side by side inside
      # the cell instead of stacking them.
      #
      # @param columns select { choices: [1, 2, 3] }
      # @param layout select { choices: [stacked, horizontal] }
      def default(columns: 2, layout: :stacked)
        render Bali::DescriptionList::Component.new(columns: columns.to_i, layout: layout.to_sym) do |c|
          c.with_item(label: 'Full name', value: 'Juan Pérez')
          c.with_item(label: 'Email', value: 'juan.perez@example.com')
          c.with_item(label: 'Phone', value: '+52 664 123 4567')
          c.with_item(label: 'Company', value: 'Grupo AFAL')
          c.with_item(label: 'City', value: 'Tijuana, B.C.')
          c.with_item(label: 'Member since', value: 'January 2024')
        end
      end

      # Items accept block content instead of `value:` for rich values —
      # a `Bali::Tag`, a link, or any HTML.
      def with_rich_values
        render_with_template
      end
    end
  end
end
