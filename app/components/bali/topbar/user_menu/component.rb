# frozen_string_literal: true

module Bali
  module Topbar
    module UserMenu
      # The prefabricated user dropdown for the Topbar's far-right slot: avatar
      # (photo or derived initials), the user's name and email as a non-actionable
      # header, the host's items, and a sign-out entry that submits a real form.
      #
      # A Bali::Dropdown with its trigger and header already chosen — the same
      # move as Bali::ActionsDropdown, so keyboard, Escape, `aria-expanded` and
      # `popover:` all come from the one controller instead of the hand-rolled
      # `<details class="dropdown">` this replaces (which had none of them).
      #
      # There is NO default sign-out route on purpose (#713): the item only
      # renders when the call site passes `sign_out: { href: ... }`, so the gem
      # stays uncoupled from bali-auth and from any host's route names. The
      # verb defaults to `:delete` — a sign-out that a crawler can GET must not
      # be expressible by accident — which routes the item through DeleteLink's
      # `button_to`: a real form submission, not an `<a>` that degrades to GET
      # without JavaScript. The delete-confirm dialog is skipped (signing out is
      # not destructive); pass `confirm:` in the hash to opt back in.
      class Component < Dropdown::Component
        SIGN_OUT_METHOD = :delete

        # Absolute keys, for the reason Dropdown::Component::MENU_LABEL_KEY
        # names: a relative key would resolve against this subclass's own scope.
        TRIGGER_LABEL_KEY = "bali_view.topbar.user_menu.trigger_label"
        SIGN_OUT_KEY = "bali_view.topbar.user_menu.sign_out"

        SIGN_OUT_MESSAGE = "Bali::Topbar::UserMenu::Component: `sign_out:` takes a Hash " \
                           "with `href:` — e.g. `sign_out: { href: sign_out_path }`. " \
                           "`method:` defaults to :delete. There is no default route: " \
                           "without `sign_out:` the item is simply not rendered."

        # @param name [String] the user's full name. Feeds the trigger's avatar
        #   (initials + deterministic colour, see Bali::Avatar) and the header.
        # @param email [String, nil] second line of the header.
        # @param avatar_url [String, nil] photo for the avatar; wins over initials.
        # @param sign_out [Hash, nil] `{ href:, method: :delete }`. Extra keys
        #   (`name:`, `confirm:`, `data:`, ...) reach the item. No hash, no item.
        # @param align [Symbol] Dropdown's horizontal axis; `:end` here, because
        #   the menu hangs off the far right of the Topbar.
        # Every other keyword is Bali::Dropdown::Component's.
        def initialize(name:, email: nil, avatar_url: nil, sign_out: nil, align: :end, **options)
          @name = name
          @email = email
          @avatar_url = avatar_url
          @sign_out = normalize_sign_out(sign_out)

          super(align: align, **prepend_class_name(options, "bali-topbar-user-menu"))
        end

        # Slot order is registration order, so the surrounding entries are added
        # here, around an explicit `content` call: header first, then the call
        # site's `with_item`s (evaluated by `content`), then sign-out.
        def before_render
          header = header_content
          with_item(tag: :title, class: "bali-topbar-user-menu-header") { header }
          content
          add_sign_out_item if @sign_out
          super
        end

        # Avatar + name (hidden on mobile) + chevron. Rendered into locals first:
        # a block that calls `render` itself comes back empty here — `capture`
        # prefers the output buffer and discards the returned string (see the
        # measurement note in Bali::ActionsDropdown#default_trigger).
        def default_trigger
          inner = safe_join([
                              render(Bali::Avatar::Component.new(
                                       name: @name, src: @avatar_url, size: :xs
                                     )),
                              tag.span(@name, class: "hidden md:inline"),
                              render(Bali::Icon::Component.new("chevron-down", size: :small))
                            ])

          render(Dropdown::Trigger::Component.new(
                   variant: :ghost,
                   class: "btn-sm gap-2",
                   "aria-label": t(TRIGGER_LABEL_KEY, name: @name)
                 )) { inner }
        end

        private

        # `tag: :title` (713-D3): the identity is not actionable, so it must not
        # be a menuitem — Dropdown::Title is presentational and does not count
        # towards `render?`, so a UserMenu with no items and no `sign_out:`
        # renders nothing at all rather than a menu with nothing to choose.
        def header_content
          safe_join([
            tag.span(@name, class: "block text-sm font-medium text-base-content"),
            (tag.span(@email, class: "block text-xs font-normal text-base-content/60") if
              @email.present?)
          ].compact)
        end

        def normalize_sign_out(sign_out)
          return nil if sign_out.nil?

          sign_out = sign_out.symbolize_keys if sign_out.respond_to?(:symbolize_keys)
          raise ArgumentError, SIGN_OUT_MESSAGE unless sign_out.is_a?(Hash) &&
                                                       sign_out[:href].present?

          { method: SIGN_OUT_METHOD }.merge(sign_out)
        end

        # Routed through the same `with_item` lambda as everything else, so
        # every non-GET verb becomes a real `button_to` form (#641): `:delete`
        # through DeleteLink, `:post`/`:patch`/`:put` through ButtonToItem, all
        # with `form_class: "contents"` for free. Signing out is not deleting a
        # record, so the confirm dialog is off unless the caller asks for one.
        def add_sign_out_item
          opts = @sign_out.except(:href, :method)
          method = @sign_out[:method].to_sym
          opts[:name] ||= t(SIGN_OUT_KEY)
          opts[:icon] ||= "log-out"
          opts[:class] = class_names("bali-topbar-sign-out", opts[:class])

          if method == SIGN_OUT_METHOD
            opts[:skip_confirm] = true unless opts.key?(:confirm) || opts.key?(:skip_confirm)
          else
            opts[:class] = class_names("text-error", opts[:class])
          end

          with_item(href: @sign_out[:href], method: method, **opts)
        end
      end
    end
  end
end
