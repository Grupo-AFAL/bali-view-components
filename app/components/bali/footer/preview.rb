# frozen_string_literal: true

module Bali
  module Footer
    class Preview < ApplicationViewComponentPreview
      # Footer
      # -------------------
      # A responsive footer component following DaisyUI patterns.
      # Supports brand section, multiple link sections, and bottom content.
      #
      # @param color select { choices: [neutral, base, primary, secondary] }
      # @param center toggle
      def default(color: :neutral, center: false)
        render Bali::Footer::Component.new(color: color.to_sym, center: center) do |footer|
          footer.with_brand(
            name: 'ACME Industries',
            description: 'Providing reliable tech since 1992. Building the future, one product at a time.'
          )

          footer.with_section(title: 'Services') do |section|
            section.with_link(name: 'Branding', href: '#')
            section.with_link(name: 'Design', href: '#')
            section.with_link(name: 'Marketing', href: '#')
            section.with_link(name: 'Advertisement', href: '#')
          end

          footer.with_section(title: 'Company') do |section|
            section.with_link(name: 'About us', href: '#')
            section.with_link(name: 'Contact', href: '#')
            section.with_link(name: 'Jobs', href: '#')
            section.with_link(name: 'Press kit', href: '#')
          end

          footer.with_section(title: 'Legal') do |section|
            section.with_link(name: 'Terms of use', href: '#')
            section.with_link(name: 'Privacy policy', href: '#')
            section.with_link(name: 'Cookie policy', href: '#')
          end

          footer.with_bottom do
            tag.p("Copyright #{Date.current.year} - All rights reserved by ACME Industries Ltd.")
          end
        end
      end

      # Minimal footer with just brand and copyright
      def minimal
        render_with_template
      end

      # Footer with social links and icons
      def with_social_links
        render_with_template
      end
    end
  end
end
