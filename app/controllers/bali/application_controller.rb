# frozen_string_literal: true

module Bali
  class ApplicationController < ActionController::Base
    # Explicit for Brakeman compliance; ActionController::Base enables this by default.
    protect_from_forgery with: :exception
  end
end
