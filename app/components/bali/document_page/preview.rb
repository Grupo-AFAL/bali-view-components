# frozen_string_literal: true

module Bali
  module DocumentPage
    class Preview < ApplicationViewComponentPreview
      # @param title text "Document title"
      # @param subtitle text "Subtitle text"
      def default(title: "Q2 2026 Product Roadmap", subtitle: "Last edited 2 hours ago")
        render Bali::DocumentPage::Component.new(
          title: title,
          subtitle: subtitle,
          breadcrumbs: [
            { name: "Dashboard", href: "/lookbook" },
            { name: "Documents", href: "/lookbook" },
            { name: title }
          ]
        ) do |page|
          page.with_title_tag do
            render Bali::Tag::Component.new(text: "Published", color: :success, size: :sm)
          end

          page.with_action do
            render Bali::Button::Component.new(name: "Edit", variant: :primary, size: :sm, icon_name: "pencil")
          end

          page.with_metadata do
            render Bali::Card::Component.new(style: :bordered) do
              tag.div(class: "card-body space-y-3") do
                safe_join([
                  tag.div(
                    tag.p("Status", class: "text-xs text-base-content/50 uppercase tracking-wider") +
                    tag.p("Published", class: "text-sm font-medium text-success")
                  ),
                  tag.div(
                    tag.p("Author", class: "text-xs text-base-content/50 uppercase tracking-wider") +
                    tag.p("Demo User", class: "text-sm")
                  ),
                  tag.div(
                    tag.p("Word Count", class: "text-xs text-base-content/50 uppercase tracking-wider") +
                    tag.p("342", class: "text-sm")
                  ),
                  tag.div(
                    tag.p("Versions", class: "text-xs text-base-content/50 uppercase tracking-wider") +
                    tag.p("3", class: "text-sm")
                  )
                ])
              end
            end
          end

          page.with_preview do
            render Bali::Card::Component.new(style: :bordered) do
              tag.div(class: "card-body") do
                tag.h3("Preview", class: "text-sm font-semibold text-base-content/60 uppercase tracking-wider mb-3") +
                tag.p("This document outlines the key objectives and milestones for the upcoming quarter. " \
                       "Our team has been working diligently on several initiatives that will significantly " \
                       "impact our product roadmap.", class: "text-base-content/80")
              end
            end
          end
        end
      end
    end
  end
end
