# frozen_string_literal: true

module Bali
  module WidgetGrid
    # The bento: a grid of `Bali::Widget::Component` cards a user can rearrange,
    # resize and remove, with the whole layout persisted on every gesture.
    #
    #   render Bali::WidgetGrid::Component.new(url: widget_layout_path) do |grid|
    #     widgets.each { |widget| grid.with_widget(widget) }
    #   end
    #
    # `url` is a host endpoint. Bali ships no controller and no routes: who may
    # see which widget is the host's rule, and the write goes through
    # `Bali::DashboardWidget::Store`.
    class Component < ApplicationViewComponent
      # The slot builds each card, so `refresh_url` is injected here rather than
      # asked of every caller — `grid.with_widget(widget, size:)` is unchanged.
      renders_many :widgets, ->(widget, **options) {
        Bali::Widget::Component.new(widget, refresh_url: refresh_url, **options)
      }

      # Only the LEADING text, never the controls. Letting a host
      # replace the whole band, which silently deleted the Edit/Done buttons —
      # and since the grid is the only surface that offers edit mode, a host that
      # wanted a heading lost the feature with nothing to tell it so.
      renders_one :heading

      renders_one :empty_state

      # Fixed row height, not `stretch`: sizes are 2-D boxes, so `large` means
      # "two rows tall", which is meaningless while rows size to content.
      #
      # `md:grid-cols-2` exists because this used to jump 1 -> 4 columns at `lg`,
      # so a tablet in portrait got a single column and none of the size system.
      #
      # Deliberately NOT `grid-flow-dense`: it backfills gaps by pulling later
      # tiles forward, which would silently overrule the order the user chose.
      GRID_CLASSES = "bali-widget-grid grid grid-cols-1 gap-4 md:grid-cols-2 " \
                     "lg:grid-cols-4 lg:auto-rows-[16rem]"

      ADD_TILE_CLASSES = "bali-widget-add-tile hidden [.editing_&]:flex flex-col items-center " \
                         "justify-center gap-2 rounded-box border-2 border-dashed " \
                         "border-base-300 text-base-content/50 transition-colors " \
                         "hover:border-primary hover:text-primary"

      # `editing_param` is the query param the mode is remembered in. Exposed
      # because a host may already use `editing` for something of their own, and
      # because a knob only reachable from hand-written markup is not reachable:
      # a host renders this component, it does not write the data attributes.
      # `refresh_url` is handed to every card, so a widget declaring
      # `refresh_every` starts polling without the host wiring anything per tile.
      def initialize(url:, add_path: nil, refresh_url: nil, editing_param: "editing", **options)
        @url = url
        @add_path = add_path
        @refresh_url = refresh_url
        @editing_param = editing_param
        @options = build_options(options)
        super()
      end

      private

      attr_reader :url, :add_path, :refresh_url, :editing_param, :options

      def build_options(opts)
        # Detached first, so every line below is writing to our own hash rather
        # than the host's. See `detach_data`.
        opts = detach_data(opts)
        opts = prepend_controller(opts, "bali-widget-grid bali-widget-grid-edit-mode")
        opts = prepend_values(opts, "bali-widget-grid", widget_grid_values)
        opts = prepend_values(opts, "bali-widget-grid-edit-mode", edit_mode_values)
        opts = prepend_data_attribute(opts, "bali-widget-grid-edit-mode-editing-class", "editing")
        prepend_action(opts, "keydown@window->bali-widget-grid-edit-mode#keydown")
      end

      # `I18n.t`, not the instance `#t`: this runs from `initialize`, before
      # `render_in` sets `@view_context` — and `ViewComponent::Translatable#t`
      # raises `TranslateCalledBeforeRenderError` without one. `Tabs::Component`
      # hits the same constraint and resolves it the same way.
      def widget_grid_values
        {
          url: url,
          moved_text: I18n.t("bali_view.widgets.edit.moved"),
          # THREE removal strings, not one with a count in it. Spanish does not
          # share a verb across them ("queda 1 widget" / "quedan 3 widgets"), and
          # this method runs at `initialize` where the count is unknowable — the
          # card being removed has not been chosen yet. So the server ships every
          # form and the controller picks the one that fits.
          removed_one_text: I18n.t("bali_view.widgets.edit.removed_one"),
          removed_other_text: I18n.t("bali_view.widgets.edit.removed_other"),
          # Its own string rather than "0 widgets remaining", which would name a
          # state the user is about to not be in: an emptied grid means "never
          # chose", so the server restores the defaults and the grid reloads.
          removed_last_text: I18n.t("bali_view.widgets.edit.removed_last"),
          resized_text: I18n.t("bali_view.widgets.edit.resized"),
          failed_text: I18n.t("bali_view.widgets.edit.failed")
        }
      end

      def edit_mode_values
        {
          param: editing_param,
          on_text: I18n.t("bali_view.widgets.edit.editing_on"),
          off_text: I18n.t("bali_view.widgets.edit.editing_off")
        }
      end

      # Dragging is gated on the HANDLE, which is `display:none` outside edit
      # mode, so a card cannot be picked up while you are reading the dashboard.
      # That is the mechanism because `SortableListController` reads `disabled`
      # only at connect — flipping the value would not re-apply.
      #
      # No `data-sortable-update-url` on the cards, so SortableList's own
      # per-item PATCH never fires: it posts a 1-based position for one item
      # where every gesture here writes the whole 0-based sequence.
      def sortable_options
        {
          handle: ".handle",
          class: GRID_CLASSES,
          data: {
            bali_widget_grid_target: "grid",
            action: "bali:sortable-list:end->bali-widget-grid#reordered"
          }
        }
      end
    end
  end
end
