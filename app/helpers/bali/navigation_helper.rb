# frozen_string_literal: true

module Bali
  # Exposed to host app views (see the engine initializer): the navigation as this request sees
  # it, for the host's own breadcrumbs and landings and for `Bali::SideMenu` and `Bali::Command`,
  # which read it through `helpers`.
  module NavigationHelper
    # One menu per navigation and view, so the side menu, the palette and the page evaluate each
    # gate once.
    #
    # @param navigation [Class<Bali::Navigation>]
    # @return [Bali::Navigation::Menu]
    def navigation_for(navigation)
      @bali_navigation_menus ||= {}
      @bali_navigation_menus[navigation] ||= navigation.menu(self)
    end
  end
end
