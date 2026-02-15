# frozen_string_literal: true

Bali::Engine.routes.draw do
  post 'block_editor/uploads', to: 'block_editor_uploads#create', as: :block_editor_uploads
end
