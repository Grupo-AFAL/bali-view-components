# frozen_string_literal: true

module Bali
  module Form
    module Switch
      class Preview < ApplicationViewComponentPreview
        # Default Toggle
        # ----------------
        # Basic toggle switch with DaisyUI styling
        def default
          render_with_template(
            template: 'bali/form/switch/previews/default',
            locals: { model: Movie.new }
          )
        end

        # Size Variants
        # -------------
        # Toggle switches in different sizes: xs, sm, md, lg
        def sizes
          render_with_template(
            template: 'bali/form/switch/previews/sizes',
            locals: { model: Movie.new }
          )
        end

        # Color Variants
        # --------------
        # Toggle switches with different semantic colors
        def colors
          render_with_template(
            template: 'bali/form/switch/previews/colors',
            locals: { model: Movie.new }
          )
        end

        # With Error State
        # ----------------
        # Toggle switch showing validation error styling
        def with_error
          movie = Movie.new
          movie.errors.add(:indie, 'must be accepted to continue')
          render_with_template(
            template: 'bali/form/switch/previews/with_error',
            locals: { model: movie }
          )
        end

        # Switch Field Group
        # -------------------
        # Toggle switch wrapped in a fieldset
        def field_group
          render_with_template(
            template: 'bali/form/switch/previews/field_group',
            locals: { model: Movie.new }
          )
        end

        # All Variants
        # ------------
        # Combined view of all toggle switch options
        def all_variants
          render_with_template(
            template: 'bali/form/switch/previews/all_variants',
            locals: { model: Movie.new }
          )
        end
      end
    end
  end
end
