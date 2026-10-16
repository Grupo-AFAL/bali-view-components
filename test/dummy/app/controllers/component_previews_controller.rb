# frozen_string_literal: true

# ViewComponent wraps only its own `previews` action in `set_locale`. Lookbook renders each
# scenario and its layout through two other actions on this controller
# (`render_scenario_to_string`, `render_in_layout_to_string`), which `?locale=` reaches only
# from here.
class ComponentPreviewsController < ViewComponentsController
  around_action :set_locale

  # `@display variant mobile` on a scenario renders a component's `+mobile` template, as a host's
  # `request.variant = :mobile` does. Lookbook writes a scenario's display options into these
  # params before it calls either action.
  before_action do
    variant = params.dig(:lookbook, :display, :variant)
    request.variant = variant.to_sym if variant
  end
end
