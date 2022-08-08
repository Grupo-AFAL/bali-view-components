# frozen_string_literal: true

module Bali
  module Form
    class Preview < ApplicationViewComponentPreview
      FORM = Bali::Utils::DummyFilterForm.new
      VALUES = { 
                'Cities': [
                            ['Tijuana', 0],
                            ['New York', 1],
                            ['Brasilia', 2],
                          ],
                'Countries': [
                               ['Mexico', 3],
                               ['USA', 4],
                               ['Brazil', 5],
                             ]
              }

      def radio_buttons_field_group
        render_with_template(
          template: 'bali/form/previews/radio_buttons_field_group',
          locals: { model: FORM, values: VALUES }
        )
      end

      def radio_buttons_field
        render_with_template(
          template: 'bali/form/previews/radio_buttons_field',
          locals: { model: FORM, values: VALUES }
        )
      end
    end
  end
end
