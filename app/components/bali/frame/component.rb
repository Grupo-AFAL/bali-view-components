# frozen_string_literal: true

module Bali
  module Frame
    # A `<turbo-frame>` with deferred loading that swaps to a placeholder while it loads.
    #
    # Turbo marks the `<turbo-frame>` with `[busy]` during ANY load: the initial
    # deferred one (`loading: :lazy` with `src`) and every reload targeted at the
    # frame —including a link with `data-turbo-frame` pointing here, or a
    # "Refresh" button—. While it is `[busy]`, the co-located CSS shows the
    # sibling `.frame-loading` card and hides the frame: the content is replaced
    # by the loading indicator and comes back when it finishes. Pure CSS, no JS.
    #
    # With `src`, the content arrives in a separate request and the placeholder
    # shows while it arrives. `loading: :lazy` defers that request until the frame
    # is visible; without `loading`, Turbo fires it immediately (eager). Both are
    # "deferred" in the sense of a separate request:
    #
    #   <%= render Bali::Frame::Component.new(
    #         id: "report", src: report_path, loading: :lazy, text: "Loading…") %>
    #
    # With its own content (the block is the frame's content; the placeholder
    # appears when the frame reloads):
    #
    #   <%= render Bali::Frame::Component.new(id: "report") do %>
    #     <table>…</table>
    #   <% end %>
    #
    # A custom placeholder (a card, a skeleton) through the `loading` slot:
    #
    #   <%= render Bali::Frame::Component.new(id: "report", src: report_path, loading: :lazy) do |frame| %>
    #     <% frame.with_loading do %><%= render Bali::Skeleton::Component.new %><% end %>
    #   <% end %>
    class Component < ApplicationViewComponent
      renders_one :loading

      # @param id [String] turbo-frame id (required)
      # @param src [String, nil] URL for deferred loading
      # @param loading [Symbol, String, nil] frame loading strategy (:lazy, :eager)
      # @param text [String, nil] text next to the spinner of the default placeholder
      def initialize(id:, src: nil, loading: nil, text: nil, **options)
        @id = id
        @src = src
        @loading = loading
        @text = text
        @options = options
      end

      private

      attr_reader :options

      def wrapper_attributes
        options.except(:class).merge(class: class_names("frame-loader", options[:class]))
      end

      def frame_attributes
        { id: @id, src: @src, loading: @loading }.compact
      end

      # Default placeholder: small spinner + text, centered and dimmed. It is used
      # in the sibling card and as the initial content of a deferred frame, unless
      # the host passes its own `loading` slot. The spinner carries role="status" +
      # aria-label (like Bali::Loader): when it becomes visible with [busy],
      # assistive technology announces that it is loading.
      def default_loading
        tag.div(class: "flex items-center justify-center gap-2 py-6 text-sm text-base-content/60") do
          safe_join([
            tag.span(class: "loading loading-spinner loading-sm", role: "status", aria: { label: display_text }),
            display_text
          ])
        end
      end

      def display_text
        @text || I18n.t("bali_view.frame.loading")
      end
    end
  end
end
