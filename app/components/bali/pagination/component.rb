# frozen_string_literal: true

module Bali
  module Pagination
    class Component < ApplicationViewComponent
      include Pagy::Frontend

      # @param pagy [Pagy] The Pagy pagination object
      # @param size [Symbol] Button size - :xs, :sm, :md (default), :lg
      # @param variant [Symbol] Button variant - :default, :outline, :ghost
      def initialize(pagy:, size: :md, variant: :default, **options)
        @pagy = pagy
        @size = size
        @variant = variant
        @options = options
      end

      def render?
        @pagy.pages > 1
      end

      private

      def btn_class
        classes = %w[join-item btn]
        classes << "btn-#{@size}" unless @size == :md
        classes << 'btn-outline' if @variant == :outline
        classes << 'btn-ghost' if @variant == :ghost
        classes.join(' ')
      end

      def btn_active_class
        "#{btn_class} btn-active"
      end

      def btn_disabled_class
        "#{btn_class} btn-disabled"
      end

      def prev_page
        @pagy.prev
      end

      def next_page
        @pagy.next
      end

      def series
        @pagy.series
      end

      def page_url(page)
        pagy_url_for(@pagy, page)
      end

      def aria_label
        I18n.t('view_components.bali.pagination.aria_label')
      end

      def prev_aria_label
        I18n.t('view_components.bali.pagination.previous_page')
      end

      def next_aria_label
        I18n.t('view_components.bali.pagination.next_page')
      end

      def page_aria_label(page)
        I18n.t('view_components.bali.pagination.page', page: page)
      end
    end
  end
end
