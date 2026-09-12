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

        # Persisted Records
        # -----------------
        # Rows the server already knows about. `fields_for` emits an `[id]`
        # hidden field for them, and that is what makes the controller hide and
        # flag a removed row instead of dropping it — the server needs the id
        # back to know what to destroy. Compare with `default`, whose unsaved
        # rows leave the DOM outright.
        #
        # `instantiate` builds a persisted record straight from attributes, so
        # the preview gets real `fields_for` output without writing to the
        # database.
        def persisted
          movie = Movie.new
          movie.association(:characters).target = [
            saved_character(10, "John Doe", 1),
            saved_character(11, "Jane Smith", 2)
          ]

          render_with_template(
            template: "bali/form/dynamic_fields/previews/persisted",
            locals: { model: movie }
          )
        end

        # Table Mode
        # ----------
        # `table: true` moves the container target onto a `<tbody>` this helper
        # renders, so the row partial emits `<tr>`. The header and its
        # `<template>` stay outside the `<table>`: a `<div>` between `<table>`
        # and `<tbody>` gets hoisted out of the table by the HTML parser, which
        # would strand the add button and its template.
        def table
          movie = Movie.new
          movie.characters.build(name: "John Doe")
          movie.characters.build(name: "Jane Smith")

          render_with_template(
            template: "bali/form/dynamic_fields/previews/table",
            locals: { model: movie }
          )
        end

        # Array Mode
        # ----------
        # `array: true` for an attribute that is a plain array of hashes rather
        # than an association: no `fields_for`, no `_destroy`, and names shaped
        # `movie[steps][][role]`.
        def array
          render_with_template(
            template: "bali/form/dynamic_fields/previews/array",
            locals: { model: Movie.new }
          )
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

        private

        # Private so Lookbook does not list it as a scenario of its own.
        #
        # `::Time`, not `Time`: a bare constant here resolves against the
        # enclosing `Bali::Form`, which has a `Time` module of its own, and the
        # preview 500s over the request path with `undefined method 'current'
        # for module Bali::Form::Time` (#843).
        def saved_character(id, name, position)
          Character.instantiate(
            "id" => id, "movie_id" => 1, "name" => name, "position" => position,
            "created_at" => ::Time.current, "updated_at" => ::Time.current
          )
        end
      end
    end
  end
end
