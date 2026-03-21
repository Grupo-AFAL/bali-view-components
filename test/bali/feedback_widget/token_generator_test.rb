# frozen_string_literal: true

require "test_helper"

class BaliFeedbackWidgetTokenGeneratorTest < ActiveSupport::TestCase
  def test_generates_valid_jwt_structure
    token = generate_token
    parts = token.split(".")

    assert_equal 3, parts.size, "JWT should have 3 segments (header.payload.signature)"
  end

  def test_header_contains_hs256_algorithm
    token = generate_token
    header = decode_segment(token, 0)

    assert_equal "HS256", header["alg"]
    assert_equal "JWT", header["typ"]
  end

  def test_payload_contains_user_fields
    token = generate_token(user_id: 42, email: "test@example.com", project_slug: "my-project")
    payload = decode_segment(token, 1)

    assert_equal 42, payload["sub"]
    assert_equal "test@example.com", payload["email"]
    assert_equal "my-project", payload["project_slug"]
  end

  def test_payload_contains_expiration
    token = generate_token(expires_in: 3600)
    payload = decode_segment(token, 1)

    assert payload["exp"].is_a?(Integer)
    assert payload["exp"] > Time.current.to_i
    assert payload["exp"] <= (Time.current + 3600).to_i + 1
  end

  def test_different_secrets_produce_different_signatures
    token1 = generate_token(secret: "secret-one")
    token2 = generate_token(secret: "secret-two")

    sig1 = token1.split(".").last
    sig2 = token2.split(".").last

    assert_not_equal sig1, sig2
  end

  def test_signature_is_deterministic_for_same_inputs
    frozen_time = Time.current
    travel_to(frozen_time) do
      token1 = generate_token
      token2 = generate_token

      assert_equal token1, token2
    end
  end

  private

  def generate_token(secret: "test-secret", project_slug: "test", user_id: 1, email: "a@b.com", expires_in: 3600)
    Bali::FeedbackWidget::TokenGenerator.call(
      secret: secret,
      project_slug: project_slug,
      user_id: user_id,
      email: email,
      expires_in: expires_in
    )
  end

  def decode_segment(token, index)
    JSON.parse(Base64.urlsafe_decode64(token.split(".")[index]))
  end
end
