# frozen_string_literal: true

module Bali
  module Form
    module SlimSelect
      class Preview < ApplicationViewComponentPreview
        OPTIONS = [
          ['Option 1', 1],
          ['Option 2', 2],
          ['Option 3', 3],
          ['Option 4', 4],
          ['Option 5', 5]
        ].freeze

        GROUPED_OPTIONS = {
          'Fruits' => [%w[Apple apple], %w[Banana banana], %w[Orange orange]],
          'Vegetables' => [%w[Carrot carrot], %w[Broccoli broccoli], %w[Spinach spinach]],
          'Dairy' => [%w[Milk milk], %w[Cheese cheese], %w[Yogurt yogurt]]
        }.freeze

        HTML_OPTIONS = [
          ['<span class="flex items-center gap-2"><span class="badge badge-success badge-xs"></span> Active User1</span>'.html_safe,
           'active', { 'data-inner-html' => '<span class="flex items-center gap-2"><span class="badge badge-success badge-xs"></span> Active User</span>'.html_safe }],
          ['<span class="flex items-center gap-2"><span class="badge badge-warning badge-xs"></span> Pending User2</span>'.html_safe,
           'pending', { 'data-inner-html' => '<span class="flex items-center gap-2"><span class="badge badge-warning badge-xs"></span> Pending User</span>'.html_safe }],
          ['<span class="flex items-center gap-2"><span class="badge badge-error badge-xs"></span> Inactive User3</span>'.html_safe,
           'inactive', { 'data-inner-html' => '<span class="flex items-center gap-2"><span class="badge badge-error badge-xs"></span> Inactive User</span>'.html_safe }]
        ].freeze

        # @label Default
        # Basic single select dropdown
        def default
          render_with_template(
            template: 'bali/form/slim_select/previews/default',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Multiple
        # Multi-select with tags for selected values
        def multiple
          render_with_template(
            template: 'bali/form/slim_select/previews/multiple',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Addable
        # Allows users to add new options that don't exist in the list
        def addable
          render_with_template(
            template: 'bali/form/slim_select/previews/addable',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Remote (AJAX)
        # Fetches options from a remote URL as user types
        def remote
          render_with_template(
            template: 'bali/form/slim_select/previews/remote',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Allow Deselect
        # Single select with X button to clear selection
        def allow_deselect
          render_with_template(
            template: 'bali/form/slim_select/previews/allow_deselect',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Disabled
        # Select in disabled state - cannot be interacted with
        def disabled
          render_with_template(
            template: 'bali/form/slim_select/previews/disabled',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label No Search
        # Hides the search input in the dropdown
        def no_search
          render_with_template(
            template: 'bali/form/slim_select/previews/no_search',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Select All
        # Multi-select with Select All / Deselect All buttons
        def select_all
          render_with_template(
            template: 'bali/form/slim_select/previews/select_all',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Placeholder
        # Custom placeholder text
        def placeholder
          render_with_template(
            template: 'bali/form/slim_select/previews/placeholder',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Hide Selected
        # Multi-select that hides already selected options from the dropdown
        def hide_selected
          render_with_template(
            template: 'bali/form/slim_select/previews/hide_selected',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Search Highlight
        # Highlights matching text in search results
        def search_highlight
          render_with_template(
            template: 'bali/form/slim_select/previews/search_highlight',
            locals: { model: form_record, options: OPTIONS }
          )
        end

        # @label Option Groups
        # Options organized into groups
        def optgroups
          render_with_template(
            template: 'bali/form/slim_select/previews/optgroups',
            locals: { model: form_record, grouped_options: GROUPED_OPTIONS }
          )
        end

        # @label Custom HTML
        # Options with custom HTML content (badges, icons, etc.)
        def custom_html
          render_with_template(
            template: 'bali/form/slim_select/previews/custom_html',
            locals: { model: form_record, html_options: HTML_OPTIONS }
          )
        end

        # @label Open Position Up
        # Dropdown opens upward instead of downward
        def open_position_up
          render_with_template(
            template: 'bali/form/slim_select/previews/open_position_up',
            locals: { model: form_record, options: OPTIONS }
          )
        end
      end
    end
  end
end
