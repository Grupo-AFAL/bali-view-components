# frozen_string_literal: true

module ApplicationHelper
  # Pagy 43+ no longer requires Pagy::Frontend include
  # Helper methods are now available on the Pagy instance directly
  include Bali::ApplicationHelper
end
