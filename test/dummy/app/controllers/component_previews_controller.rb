# frozen_string_literal: true

# ViewComponent wraps only its own `previews` action in `set_locale`. Lookbook renders each
# scenario and its layout through two other actions on this controller
# (`render_scenario_to_string`, `render_in_layout_to_string`), which `?locale=` reaches only
# from here.
class ComponentPreviewsController < ViewComponentsController
  around_action :set_locale
end
