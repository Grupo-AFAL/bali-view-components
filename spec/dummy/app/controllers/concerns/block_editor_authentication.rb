# frozen_string_literal: true

module BlockEditorAuthentication
  extend ActiveSupport::Concern

  private

  # In the dummy app, user identity comes from a request header.
  # Production apps should replace this with their own authentication.
  def current_user_id
    request.headers['X-User-Id'] || '1'
  end
end
