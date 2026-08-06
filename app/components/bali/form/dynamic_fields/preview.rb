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
          movie.characters.build(name: "John Doe")
          movie.characters.build(name: "Jane Smith")

          render_with_template(
            template: "bali/form/dynamic_fields/previews/default",
            locals: { model: movie }
          )
        end

        # Empty State
        # -----------
        # Dynamic fields with no initial records
        def empty
          render_with_template(
            template: "bali/form/dynamic_fields/previews/empty",
            locals: { model: Movie.new }
          )
        end

        # With Custom Block
        # -----------------
        # Custom header layout using a block
        def with_custom_block
          movie = Movie.new
          movie.characters.build(name: "Example Character")

          render_with_template(
            template: "bali/form/dynamic_fields/previews/with_custom_block",
            locals: { model: movie }
          )
        end

        # Custom Button Styling
        # ---------------------
        # Dynamic fields with custom button classes
        def custom_button
          render_with_template(
            template: "bali/form/dynamic_fields/previews/custom_button",
            locals: { model: Movie.new }
          )
        end

        # Sortable
        # --------
        # Rows carrying a hidden `[data-position]` input plus move up/down
        # buttons, mirroring the markup host apps wire by hand today — the Ruby
        # helper does not emit positions or move buttons yet. Exists to freeze
        # the moveUp/moveDown/resetPositionValues contract of the
        # dynamic-fields Stimulus controller (Cypress:
        # dynamic-fields-controller.cy.js).
        def sortable
          render_with_template(template: "bali/form/dynamic_fields/previews/sortable")
        end

        # Remove Duplicates
        # -----------------
        # The controller's `remove-duplicates` mode: cloned templates drop
        # options already selected in other rows, and the add button disables
        # once every option is in use. The Ruby helper does not emit this mode
        # yet, so the markup is wired by hand the way host apps do. Exists to
        # freeze the JS contract (Cypress: dynamic-fields-controller.cy.js).
        def remove_duplicates
          render_with_template(template: "bali/form/dynamic_fields/previews/remove_duplicates")
        end
      end
    end
  end
end
