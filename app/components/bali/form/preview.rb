# frozen_string_literal: true

module Bali
  module Form
    class Preview < ApplicationViewComponentPreview
      FORM = Bali::Utils::DummyFilterForm.new
      VALUES = { 
                'Cities': [
                            ['Tijuana', 0],
                            ['New York', 1],
                            ['Brasilia', 2]
                          ],
                'States': [
                            ['Baja California', 3],
                            ['New York', 4],
                            ['Central-West', 5],
                          ],
                'Countries': [
                               ['Mexico', 6],
                               ['USA', 7],
                               ['Brazil', 8],
                             ]
              }

      # @param keep_selection toggle
      def radio_buttons_field_group(keep_selection: false)
        render_with_template(
          template: 'bali/form/previews/radio_buttons_field_group',
          locals: { model: FORM, values: VALUES, keep_selection: keep_selection }
        )
      end

      # @param keep_selection toggle
      def radio_buttons_field(keep_selection: false)
        render_with_template(
          template: 'bali/form/previews/radio_buttons_field',
          locals: { model: FORM, values: VALUES, keep_selection: keep_selection  }
        )
      end
    end
  end
end
