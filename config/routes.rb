# frozen_string_literal: true

Bali::Engine.routes.draw do
  post 'block_editor/uploads', to: 'block_editor_uploads#create', as: :block_editor_uploads

  # B2 — storage default de las vistas guardadas del DataTable. Sin index/show: las lista
  # el FilterForm. El create recibe el storage_id en el query string de la URL del form.
  resources :saved_views, only: %i[create update destroy]

  # #707 — el registro versionado va en el query string (`?record_type=&record_id=`), no en
  # la ruta: el engine no conoce los modelos del host. Por eso `restore` es de colección y
  # recibe el `version_id` en el body, tal como lo manda document_editor/index.js.
  resources :content_versions, only: %i[index show] do
    post :restore, on: :collection
  end
end
