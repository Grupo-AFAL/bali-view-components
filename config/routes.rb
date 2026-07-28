# frozen_string_literal: true

Bali::Engine.routes.draw do
  post 'block_editor/uploads', to: 'block_editor_uploads#create', as: :block_editor_uploads

  # B2 — storage default de las vistas guardadas del DataTable. Sin index/show: las lista
  # el FilterForm. El create recibe el storage_id en el query string de la URL del form.
  resources :saved_views, only: %i[create update destroy]
end
