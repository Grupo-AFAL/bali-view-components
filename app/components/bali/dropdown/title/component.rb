# frozen_string_literal: true

module Bali
  module Dropdown
    module Title
      # A menu section heading: it is what lets items be GROUPED under a name without
      # opening a submenu.
      #
      # A span and not an `<li>`: the Dropdown template already wraps every item in
      # `<li role="none">`.
      class Component < ApplicationViewComponent
        # `role="presentation"`: inside a `<ul role="menu">` a generic span is a child that
        # role does not allow (only menuitem/group/separator), and the screen reader in menu
        # mode skips it anyway. Marked as presentational it stops being an invalid child, and
        # the text stays available for the `aria-describedby` through which the section's
        # items claim it (see PageComponents::Shared#export_menu_items).
        def initialize(name: nil, **options)
          @name = name
          @options = prepend_class_name(options, "menu-title").reverse_merge(role: "presentation")
        end

        # The Dropdown filters its items by this predicate before rendering them (see
        # Dropdown::Component#render? and its template): a heading has no permissions.
        def authorized?
          true
        end

        # A menu of headings alone is not a menu — what decides whether the Dropdown renders
        # is `render?`, and without this marker a title on its own was enough to open an
        # empty menu.
        def menu_title?
          true
        end

        def call
          tag.span(@name || content, **@options)
        end
      end
    end
  end
end
