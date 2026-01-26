# frozen_string_literal: true

module Bali
  module Form
    module Boolean
      class Preview < ApplicationViewComponentPreview
        # Default Checkbox
        # ----------------
        # Basic checkbox with DaisyUI styling
        def default
          render_with_template(
            template: 'bali/form/boolean/previews/default',
            locals: { model: Movie.new }
          )
        end

        # Size Variants
        # -------------
        # Checkboxes in different sizes: xs, sm, md, lg
        def sizes
          render_with_template(
            template: 'bali/form/boolean/previews/sizes',
            locals: { model: Movie.new }
          )
        end

        # Color Variants
        # --------------
        # Checkboxes with different semantic colors
        def colors
          render_with_template(
            template: 'bali/form/boolean/previews/colors',
            locals: { model: Movie.new }
          )
        end

        # With Error State
        # ----------------
        # Checkbox showing validation error styling
        def with_error
          movie = Movie.new
          movie.errors.add(:indie, 'must be accepted to continue')
          render_with_template(
            template: 'bali/form/boolean/previews/with_error',
            locals: { model: movie }
          )
        end

        # Boolean Field Group
        # -------------------
        # Checkbox wrapped in a fieldset
        def field_group
          render_with_template(
            template: 'bali/form/boolean/previews/field_group',
            locals: { model: Movie.new }
          )
        end

        # All Variants
        # ------------
        # Combined view of all checkbox options
        def all_variants
          render_with_template(
            template: 'bali/form/boolean/previews/all_variants',
            locals: { model: Movie.new }
          )
        end
      end
    end
  end
end
