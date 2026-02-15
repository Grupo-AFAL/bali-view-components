# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Block Editor Uploads', type: :request do
  let(:valid_image) do
    Rack::Test::UploadedFile.new(
      Rails.root.join('app/assets/images/avatar.png'),
      'image/png'
    )
  end

  before do
    allow(Bali).to receive(:block_editor_enabled).and_return(true)
    allow(Bali).to receive(:block_editor_upload_authorize).and_return(nil)
    allow(Bali).to receive(:block_editor_upload_handler).and_return(nil)
    allow(Bali).to receive(:block_editor_allowed_upload_types).and_return(nil)
    allow(Bali).to receive(:block_editor_max_upload_size).and_return(nil)
  end

  describe 'POST /bali/block_editor/uploads' do
    it 'uploads a file via Active Storage and returns a URL' do
      post bali.block_editor_uploads_path, params: { file: valid_image }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['url']).to be_present
      expect(json['url']).to start_with('/')
    end

    it 'returns error when no file is provided' do
      post bali.block_editor_uploads_path, params: {}

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['error']).to include('file')
    end

    it 'rejects files with disallowed MIME types' do
      ruby_file = Rack::Test::UploadedFile.new(
        Rails.root.join('config/routes.rb'),
        'application/x-ruby'
      )

      post bali.block_editor_uploads_path, params: { file: ruby_file }

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['error']).to include('not allowed')
    end

    it 'rejects files with blocked extensions' do
      file = Tempfile.new(['script', '.sh'])
      file.write('#!/bin/bash')
      file.rewind
      shell_file = Rack::Test::UploadedFile.new(file.path, 'text/plain')

      post bali.block_editor_uploads_path, params: { file: shell_file }

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['error']).to include('not allowed')
    ensure
      file&.close
      file&.unlink
    end

    it 'rejects files exceeding max size' do
      allow(Bali).to receive(:block_editor_max_upload_size).and_return(1.byte)

      post bali.block_editor_uploads_path, params: { file: valid_image }

      expect(response).to have_http_status(:unprocessable_entity)
      json = response.parsed_body
      expect(json['error']).to include('exceeds')
    end

    context 'with authorization' do
      it 'returns forbidden when authorize lambda returns false' do
        allow(Bali).to receive(:block_editor_upload_authorize)
          .and_return(->(_controller) { false })

        post bali.block_editor_uploads_path, params: { file: valid_image }

        expect(response).to have_http_status(:forbidden)
      end

      it 'allows upload when authorize lambda returns true' do
        allow(Bali).to receive(:block_editor_upload_authorize)
          .and_return(->(_controller) { true })

        post bali.block_editor_uploads_path, params: { file: valid_image }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'with custom upload handler' do
      it 'uses the custom handler and returns its URL' do
        handler = ->(file, _controller) { "/custom/uploads/#{file.original_filename}" }
        allow(Bali).to receive(:block_editor_upload_handler).and_return(handler)

        post bali.block_editor_uploads_path, params: { file: valid_image }

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['url']).to include('avatar.png')
      end

      it 'returns error when handler returns nil' do
        handler = ->(_file, _controller) {}
        allow(Bali).to receive(:block_editor_upload_handler).and_return(handler)

        post bali.block_editor_uploads_path, params: { file: valid_image }

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to include('no URL')
      end

      it 'returns error when handler returns an invalid URL' do
        handler = ->(_file, _controller) { 'javascript:alert(1)' }
        allow(Bali).to receive(:block_editor_upload_handler).and_return(handler)

        post bali.block_editor_uploads_path, params: { file: valid_image }

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json['error']).to include('invalid URL')
      end
    end
  end
end
