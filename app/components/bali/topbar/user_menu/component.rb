# frozen_string_literal: true

module Bali
  module Topbar
    module UserMenu
      # The prefabricated user dropdown for the Topbar's far-right slot: avatar
      # (photo or initials), the user's name and email as a non-actionable
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
        DARK_MODE_KEY = "bali_view.topbar.user_menu.dark_mode"

        # The lines wrap instead of truncating with the whole text in `title`: Sentry copies
        # `title` into the selector of a click breadcrumb, so the email would travel with it.
        HEADER_CLASSES = "bali-topbar-user-menu-header wrap-anywhere"

        SIGN_OUT_MESSAGE = "Bali::Topbar::UserMenu::Component: `sign_out:` takes a Hash " \
                           "with `href:` — e.g. `sign_out: { href: sign_out_path }`. " \
                           "`method:` defaults to :delete. There is no default route: " \
                           "without `sign_out:` the item is simply not rendered."

        # @param name [String] the user's full name. Feeds the trigger's avatar
        #   (initials + deterministic colour, see Bali::Avatar) and the header.
        # @param initials [String, nil] the avatar's letters, passed to Bali::Avatar as
        #   given. Left out, Avatar takes the first and the last word of `name:`, which
        #   reads "Federico González Pérez" as "FP".
        # @param email [String, nil] second line of the header.
        # @param avatar_url [String, nil] photo for the avatar; wins over initials.
        # @param sign_out [Hash, nil] `{ href:, method: :delete }`. Extra keys
        #   (`name:`, `confirm:`, `data:`, ...) reach the item. No hash, no item.
        # @param align [Symbol] Dropdown's horizontal axis; `:end` here, because
        #   the menu hangs off the far right of the Topbar.
        # Every other keyword is Bali::Dropdown::Component's.
        def initialize(name:, initials: nil, email: nil, avatar_url: nil, sign_out: nil,
                       align: :end, **options)
          @name = name
          @initials = initials
          @email = email
          @avatar_url = avatar_url
          @sign_out = normalize_sign_out(sign_out)

          super(align: align, **prepend_class_name(options, "bali-topbar-user-menu"))
        end

        # Slot order is registration order, so the surrounding entries are added
        # here, around an explicit `content` call: header first, then the call
        # site's `with_item`s (evaluated by `content`), then the dark-mode switch,
        # then sign-out.
        def before_render
          header = header_content
          with_item(tag: :title, class: HEADER_CLASSES) { header }
          content
          add_dark_mode_item if ThemeHelper.dark_mode?
          add_sign_out_item if @sign_out
          super
        end

        # Avatar + name + chevron. Rendered into locals first: a block that calls
        # `render` itself comes back empty here — `capture` prefers the output buffer
        # and discards the returned string (see the measurement note in
        # Bali::ActionsDropdown#default_trigger).
        #
        # Why the avatar stands alone below sm: at 320 px, beside the hamburger, the
        # palette and two actions, avatar and chevron ended at x=335, 15 px past the
        # screen edge where AppLayout clips.
        def default_trigger
          avatar = Bali::Avatar::Component.new(name: @name, initials: @initials,
                                               src: @avatar_url, size: :xs)
          chevron = Bali::Icon::Component.new("chevron-down", size: :small, class: "max-sm:hidden")
          inner = safe_join([
                              render(avatar),
                              tag.span(@name, class: "hidden md:inline max-w-48 truncate"),
                              render(chevron)
                            ])

          render(Dropdown::Trigger::Component.new(
                   variant: :ghost,
                   class: "btn-sm gap-2 max-sm:btn-square",
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
            (tag.span(@email, class: "block text-xs font-normal text-base-content/70") if
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

        # The theme names and the cookie's name travel as values; the controller writes
        # "dark" or "light" into that cookie, which Bali::ThemeHelper reads back.
        def add_dark_mode_item
          themes = Bali.themes
          with_item(tag: :button, name: t(DARK_MODE_KEY), icon: "moon",
                    role: "menuitemcheckbox",
                    "aria-checked": ThemeHelper.dark?(request).to_s,
                    class: "bali-theme-toggle",
                    data: { controller: "theme-toggle", action: "theme-toggle#toggle",
                            theme_toggle_light_value: themes[:light],
                            theme_toggle_dark_value: themes[:dark],
                            theme_toggle_cookie_value: ThemeHelper::COOKIE }) do
            tag.span(class: "bali-theme-toggle-switch", "aria-hidden": "true")
          end
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
