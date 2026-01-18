# frozen_string_literal: true

module Bali
  module Form
    module DynamicFields
      class Preview < ApplicationViewComponentPreview
        # Default Dynamic Fields
        # ----------------------
        # Basic dynamic fields group with add/remove functionality.
        # Uses the Movie model with has_many :characters association.
        def default
          movie = Movie.new
          movie.characters.build(name: 'John Doe')
          movie.characters.build(name: 'Jane Smith')

          render_with_template(
            template: 'bali/form/dynamic_fields/previews/default',
            locals: { model: movie }
          )
        end

        # Empty State
        # -----------
        # Dynamic fields with no initial records
        def empty
          render_with_template(
            template: 'bali/form/dynamic_fields/previews/empty',
            locals: { model: Movie.new }
          )
        end

        # With Custom Block
        # -----------------
        # Custom header layout using a block
        def with_custom_block
          movie = Movie.new
          movie.characters.build(name: 'Example Character')

          render_with_template(
            template: 'bali/form/dynamic_fields/previews/with_custom_block',
            locals: { model: movie }
          )
        end

        # Custom Button Styling
        # ---------------------
        # Dynamic fields with custom button classes
        def custom_button
          render_with_template(
            template: 'bali/form/dynamic_fields/previews/custom_button',
            locals: { model: Movie.new }
          )
        end
      end
    end
  end
end
