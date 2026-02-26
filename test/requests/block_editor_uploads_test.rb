# frozen_string_literal: true

require "test_helper"

class BlockEditorUploadsTest < ActionDispatch::IntegrationTest
  def setup
    @orig_enabled        = Bali.block_editor_enabled
    @orig_authorize      = Bali.block_editor_upload_authorize
    @orig_handler        = Bali.block_editor_upload_handler
    @orig_allowed_types  = Bali.block_editor_allowed_upload_types
    @orig_max_size       = Bali.block_editor_max_upload_size

    Bali.block_editor_enabled               = true
    Bali.block_editor_upload_authorize      = nil
    Bali.block_editor_upload_handler        = nil
    Bali.block_editor_allowed_upload_types  = nil
    Bali.block_editor_max_upload_size       = nil
  end

  def teardown
    Bali.block_editor_enabled               = @orig_enabled
    Bali.block_editor_upload_authorize      = @orig_authorize
    Bali.block_editor_upload_handler        = @orig_handler
    Bali.block_editor_allowed_upload_types  = @orig_allowed_types
    Bali.block_editor_max_upload_size       = @orig_max_size
  end

  def valid_image
    Rack::Test::UploadedFile.new(
      Rails.root.join("app/assets/images/avatar.png"),
      "image/png"
    )
  end

  def test_post_bali_block_editor_uploads_uploads_a_file_via_active_storage_and_returns_a_url
    post bali.block_editor_uploads_path, params: { file: valid_image }
    assert_response :ok
    json = response.parsed_body
    assert(json["url"].present?)
    assert(json["url"].start_with?("/"))
  end

  def test_post_bali_block_editor_uploads_returns_error_when_no_file_is_provided
    post bali.block_editor_uploads_path, params: {}
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_includes(json["error"], "file")
  end

  def test_post_bali_block_editor_uploads_rejects_files_with_disallowed_mime_types
    ruby_file = Rack::Test::UploadedFile.new(
    Rails.root.join("config/routes.rb"), "application/x-ruby"
    )
    post bali.block_editor_uploads_path, params: { file: ruby_file }
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_includes(json["error"], "not allowed")
  end

  def test_post_bali_block_editor_uploads_rejects_files_with_blocked_extensions
    file = Tempfile.new([ "script", ".sh" ])
    file.write("#!/bin/bash")
    file.rewind
    shell_file = Rack::Test::UploadedFile.new(file.path, "text/plain")
    post bali.block_editor_uploads_path, params: { file: shell_file }
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_includes(json["error"], "not allowed")
  ensure
    file&.close
    file&.unlink
  end

  def test_post_bali_block_editor_uploads_rejects_files_exceeding_max_size
    Bali.block_editor_max_upload_size = 1.byte
    post bali.block_editor_uploads_path, params: { file: valid_image }
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_includes(json["error"], "exceeds")
  end
  def test_post_bali_block_editor_uploads_with_authorization_returns_forbidden_when_authorize_lambda_returns_false
    Bali.block_editor_upload_authorize = ->(_controller) { false }
    post bali.block_editor_uploads_path, params: { file: valid_image }
    assert_response :forbidden
  end

  def test_post_bali_block_editor_uploads_with_authorization_allows_upload_when_authorize_lambda_returns_true
    Bali.block_editor_upload_authorize = ->(_controller) { true }
    post bali.block_editor_uploads_path, params: { file: valid_image }
    assert_response :ok
  end

  def test_post_bali_block_editor_uploads_with_custom_upload_handler_uses_the_custom_handler_and_returns_its_url
    handler = ->(file, _controller) { "/custom/uploads/#{file.original_filename}" }
    Bali.block_editor_upload_handler = handler
    post bali.block_editor_uploads_path, params: { file: valid_image }
    assert_response :ok
    json = response.parsed_body
    assert_includes(json["url"], "avatar.png")
  end

  def test_post_bali_block_editor_uploads_with_custom_upload_handler_returns_error_when_handler_returns_nil
    handler = ->(_file, _controller) { }
    Bali.block_editor_upload_handler = handler
    post bali.block_editor_uploads_path, params: { file: valid_image }
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_includes(json["error"], "no URL")
  end

  def test_post_bali_block_editor_uploads_with_custom_upload_handler_returns_error_when_handler_returns_an_invalid_url
    handler = ->(_file, _controller) { "javascript:alert(1)" }
    Bali.block_editor_upload_handler = handler
    post bali.block_editor_uploads_path, params: { file: valid_image }
    assert_response :unprocessable_entity
    json = response.parsed_body
    assert_includes(json["error"], "invalid URL")
  end
end
