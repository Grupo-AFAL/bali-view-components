# frozen_string_literal: true

module Bali
  module Pagination
    class Component < ApplicationViewComponent
      # Everything this component knows about Pagy goes through PagyAdapter; nothing here
      # touches the gem directly.
      #
      # @param pagy [Pagy] The Pagy pagination object
      # @param size [Symbol] Button size - :xs, :sm, :md (default), :lg
      # @param variant [Symbol] Button variant - :default, :outline, :ghost
      # @param url [String] Base URL for the page links. Only needed when the Pagy was not
      #   built by the `pagy()` helper (a bare `Pagy::Offset.new` carries no request and
      #   cannot build URLs). When given it wins over the Pagy's own URLs, so it has to
      #   carry any query string that must survive paging.
      # @param fragment [String] Anchor appended to every page link, e.g. "#results", so a
      #   paginator halfway down the page does not jump the reader to the top. With the
      #   `pagy()` helper `pagy(scope, fragment: "#results")` does the same thing.
      # @param data [Hash] data attributes for every page link, e.g.
      #   `{ turbo_frame: "movies" }` to page inside a Turbo Frame.
      def initialize(pagy:, size: :md, variant: :default, url: nil, fragment: nil, data: nil)
        @pagy = pagy
        @size = size
        @variant = variant
        @url = url
        @fragment = fragment
        @data = data
      end

      def render?
        adapter.navigable?
      end

      private

      def adapter
        @adapter ||= PagyAdapter.new(@pagy, base_url: @url, fragment: @fragment)
      end

      def btn_class
        classes = %w[join-item btn]
        classes << "btn-#{@size}" unless @size == :md
        classes << "btn-outline" if @variant == :outline
        classes << "btn-ghost" if @variant == :ghost
        classes.join(" ")
      end

      # `btn-active` SOLO no se ve: en daisyUI 5 oscurece apenas un `btn` plano, así que la
      # página actual quedaba indistinguible de las demás aunque el marcado ya fuera correcto
      # (`aria-current="page"`). El resto de Bali marca "esto es lo seleccionado" con
      # `btn-active btn-primary` (ver `ViewSwitch::View`), y la paginación se alinea.
      def btn_active_class
        "#{btn_class} btn-active btn-primary"
      end

      def btn_disabled_class
        "#{btn_class} btn-disabled"
      end

      def prev_page
        adapter.previous_page
      end

      def next_page
        adapter.next_page
      end

      def series
        adapter.series
      end

      def page_url(page)
        adapter.page_url(page)
      end

      def aria_label
        I18n.t("bali_view.pagination.aria_label")
      end

      def prev_aria_label
        I18n.t("bali_view.pagination.previous_page")
      end

      def next_aria_label
        I18n.t("bali_view.pagination.next_page")
      end

      def page_aria_label(page)
        I18n.t("bali_view.pagination.page", page: page)
      end
    end
  end
end
