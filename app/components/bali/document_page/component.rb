# frozen_string_literal: true

module Bali
  module DocumentPage
    class Component < ApplicationViewComponent
      include PageComponents::Shared

      renders_many :title_tags
      renders_many :actions
      renders_one :metadata
      renders_one :subheader
      renders_one :preview

      def initialize(
        title:,
        subtitle: nil,
        breadcrumbs: [],
        back: nil,
        initial_content: nil,
        toc_open: true,
        metadata_open: true,
        **options
      )
        @title = title
        @subtitle = subtitle
        @breadcrumbs = breadcrumbs.map(&:symbolize_keys)
        @back = back
        @initial_content = initial_content
        @toc_open = toc_open
        @metadata_open = metadata_open
        @options = options
      end

      def block_editor?
        @initial_content.present?
      end

      def toc?
        block_editor?
      end

      def three_panel?
        toc? || metadata?
      end

      private

      attr_reader :title, :subtitle, :breadcrumbs, :back,
                  :initial_content, :options

      def container_attributes
        options.except(:class).merge(
          class: class_names("document-page-component", options[:class]),
          data: controller_data
        )
      end

      def controller_data
        {
          controller: "document-page",
          document_page_toc_open_value: @toc_open,
          document_page_metadata_open_value: @metadata_open
        }
      end
    end
  end
end
