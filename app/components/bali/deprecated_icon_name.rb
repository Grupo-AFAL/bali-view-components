# frozen_string_literal: true

module Bali
  # One release cycle of compatibility for `icon_name:`, the spelling v3 replaced with
  # `icon:` in every component that is handed the name of an icon. Everything here is
  # removed in 4.0.
  #
  # Which components carry the shim was measured, not guessed. The eight applications that
  # render the package — afal-apps, ga-apps, gobierno-corporativo, centinela-web,
  # costa-norte, identity, opina and bali-auth — were counted call site by call site, with
  # a six-line window after each render so that a keyword on a continuation line is not
  # missed:
  #
  #   Bali::Link::Component               386   (breadcrumb items reach it through their own)
  #   Bali::Breadcrumb::Item::Component   188   (`breadcrumbs: [{ icon_name: }]` on a page)
  #   Bali::StatCard::Component            74
  #   Bali::Dropdown::Component#with_item  30
  #   Bali::Button::Component               5
  #   Bali::DeleteLink::Component           2
  #   Bali::ImageField::Input::Component    0
  #
  # 685 call sites, which makes this the largest single surface of the v3 migration — for
  # comparison, `text_field_group`, the helper that earned its own shim in #675, had 329.
  #
  # Unlike those renamed helpers, though, traffic is not what decides whether a component
  # keeps the old keyword: all of them do, including the one no application calls. A
  # renamed method that nobody calls can simply disappear, because calling it then raises
  # `NoMethodError` and says so. A keyword cannot: every one of these signatures ends in
  # `**options` and forwards the leftovers to the outer tag, so a deleted `icon_name:`
  # comes back out as a literal `icon_name="trash"` attribute on the element, with no icon
  # drawn and nothing anywhere to read. `NoMethodError` was the cheapest possible signal
  # for a renamed method; for a removed keyword the only signal is silence, so the keyword
  # stays and warns.
  module DeprecatedIconName
    REPLACEMENT = "Use `icon:`, the one spelling every Bali component now takes for the " \
                  "name of an icon. Removed in Bali 4.0."

    private

    # Returns the deprecated value, so a component can write
    # `@icon = icon || deprecated_icon_name(icon_name)` and let the new keyword win.
    # A call site that passes both is deliberately silent: `||` never evaluates the right
    # side, and a keyword whose value is discarded has nothing to warn about — deleting it
    # in 4.0 will not change what that call renders.
    #
    # @param on [String, nil] the slot writer the keyword arrives through, for the
    #   components that take it somewhere other than `new`.
    # @param hint [String, nil] one more sentence, for a component where `icon:` is not
    #   simply the old value under a new name.
    #
    # The seven messages open with the same words on purpose — `<Component> \`icon_name:\`
    # is deprecated` — so that one grep of a host's logs finds every one of them.
    def deprecated_icon_name(value, on: nil, hint: nil)
      return if value.blank?

      subject = "#{self.class.name} `icon_name:` is deprecated"
      subject += " on `#{on}`" if on

      Bali.deprecator.warn([ "#{subject}.", REPLACEMENT, hint ].compact.join(" "))
      value
    end
  end
end
