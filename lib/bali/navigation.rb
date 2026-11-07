# frozen_string_literal: true

require_relative "navigation/node"
require_relative "navigation/location"
require_relative "navigation/menu"
require_relative "navigation/base"

module Bali
  # An app's navigation, declared once: app modules (optional) → sections → items, from which
  # `Bali::SideMenu` and `Bali::Command` draw themselves (`navigation:`) and which answers where
  # a controller belongs (`locate`). The app subclasses `Bali::Navigation::Base`.
  #
  # Whatever depends on the person or the request — a gate, a path, a landing, a badge — is a
  # lambda run with `instance_exec` in the view, where `main_app`, the engines' route proxies,
  # `policy` and `current_user` exist. Bali names no user, permission or policy library.
  #
  # @example
  #   class Navigation < Bali::Navigation::Base
  #     authorize { |keys| Array(keys).any? { current_user.can?(it) } }
  #
  #     app_module :finance, icon: "landmark", controllers: %w[finance] do
  #       item :finance_cfdis, icon: "file-text", path: :finance_cfdis_path,
  #            gate: "finance.fiscal.view", controllers: %w[finance/cfdis]
  #     end
  #   end
  #
  # See docs/guides/navigation.md.
  module Navigation
    # A node and one of its `controllers:` entries, or an `outside_menu` entry (no node).
    Claim = Struct.new(:node, :entry, :index) do
      def self.covers?(entry, path)
        path == entry || path.start_with?("#{entry}/")
      end

      def matches?(path)
        self.class.covers?(entry, path)
      end
    end
  end
end
