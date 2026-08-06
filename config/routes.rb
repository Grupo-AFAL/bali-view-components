# frozen_string_literal: true

Bali::Engine.routes.draw do
  post 'block_editor/uploads', to: 'block_editor_uploads#create', as: :block_editor_uploads

  # B2 — storage default de las vistas guardadas del DataTable. Sin index/show: las lista
  # el FilterForm. El create recibe el storage_id en el query string de la URL del form.
  resources :saved_views, only: %i[create update destroy]

  # #708 — referencias de entidades del BlockEditor. El GET atiende tanto la búsqueda (?q=)
  # como la resolución por query string; el POST es el que usa el JS al cargar un documento,
  # porque la lista de refs no cabe cómodamente en una URL.
  get 'entity_references', to: 'entity_references#index', as: :entity_references
  post 'entity_references/resolve', to: 'entity_references#resolve', as: :resolve_entity_references
end
