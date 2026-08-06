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

  # #707 — el registro versionado va en el query string (`?record_type=&record_id=`), no en
  # la ruta: el engine no conoce los modelos del host. Por eso `restore` es de colección y
  # recibe el `version_id` en el body, tal como lo manda document_editor/index.js.
  resources :content_versions, only: %i[index show] do
    post :restore, on: :collection
  end

  # #706 — los nueve endpoints del contrato de RESTThreadStore.js. El `path` fija la
  # base URL que el store recibe (`comments: { url: ... }`); todo lo demás cuelga de
  # ella tal cual lo arma `_buildUrl`. El commentable viaja en el query string de esa
  # misma base, así que llega a los nueve sin que la ruta lo declare.
  resources :block_editor_threads, path: "block_editor_comments", only: %i[index create update destroy] do
    resources :comments, controller: "block_editor_threads/comments", only: %i[create update destroy] do
      resource :reactions, controller: "block_editor_threads/comments/reactions", only: %i[create destroy]
    end
  end
end
