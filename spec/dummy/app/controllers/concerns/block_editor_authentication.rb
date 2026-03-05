# frozen_string_literal: true

module BlockEditorAuthentication
  extend ActiveSupport::Concern

  private

  # In the dummy app, user identity comes from a request header.
  # Production apps should replace this with their own authentication.
  def current_user_id
    request.headers['X-User-Id'] || '1'
  end

  # BlockNote sends body as a JSON object (not a scalar), so we cannot use
  # params.permit(:body) — Rails strong params silently drops non-scalar values.
  # This helper extracts arbitrary JSON params safely.
  def permit_json(val)
    val.respond_to?(:to_unsafe_h) ? val.to_unsafe_h : val
  end
end
