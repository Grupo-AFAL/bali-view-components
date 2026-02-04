# frozen_string_literal: true

module Bali
  module Pagination
    class Component < ApplicationViewComponent
      # Pagy 43+ no longer requires Pagy::Frontend include
      # URL generation is now done via @pagy.page_url(page)

      # @param pagy [Pagy] The Pagy pagination object
      # @param size [Symbol] Button size - :xs, :sm, :md (default), :lg
      # @param variant [Symbol] Button variant - :default, :outline, :ghost
      # @param url [String] Optional base URL for pagination links (defaults to request.path)
      def initialize(pagy:, size: :md, variant: :default, url: nil, **options)
        @pagy = pagy
        @size = size
        @variant = variant
        @url = url
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
        # Pagy 43.x uses `previous` instead of `prev`
        @pagy.previous
      end

      def next_page
        @pagy.next
      end

      def series
        # Pagy 43.x series is accessed via send since it's protected
        @pagy.send(:series)
      end

      def page_url(page)
        # Pagy 43.x uses @pagy.page_url which requires a request object
        # For compatibility, we check if page_url works, otherwise fall back to simple URL
        if @pagy.respond_to?(:page_url, true) && @pagy.instance_variable_get(:@request)
          @pagy.page_url(page)
        else
          build_page_url(page)
        end
      end

      def build_page_url(page)
        base = @url || helpers.request.path
        # Build URL with page param
        uri = URI.parse(base)
        params = Rack::Utils.parse_nested_query(uri.query || '')
        page_key = @pagy.options[:page_key] || 'page'
        params[page_key] = page
        uri.query = Rack::Utils.build_nested_query(params)
        uri.to_s
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
