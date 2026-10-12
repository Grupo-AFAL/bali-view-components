# frozen_string_literal: true

Bali::Engine.routes.draw do
  post 'block_editor/uploads', to: 'block_editor_uploads#create', as: :block_editor_uploads

  # B2 — default storage for the DataTable's saved views. No index/show: the FilterForm
  # lists them. Create receives the storage_id in the query string of the form's URL.
  resources :saved_views, only: %i[create update destroy]

  # #708 — BlockEditor entity references. The GET serves both the search (?q=) and the
  # resolution by query string; the POST is what the JS uses when it loads a document,
  # because the list of refs does not fit comfortably in a URL.
  get 'entity_references', to: 'entity_references#index', as: :entity_references
  post 'entity_references/resolve', to: 'entity_references#resolve', as: :resolve_entity_references

  # #707 — the versioned record travels in the query string (`?record_type=&record_id=`), not
  # in the route: the engine does not know the host's models. That is why `restore` is a
  # collection route and receives the `version_id` in the body, as document_editor/index.js sends it.
  resources :content_versions, only: %i[index show] do
    post :restore, on: :collection
  end

  # #721 — the archived record travels in the query string, as in content versions.
  resources :archivals, only: %i[new create] do
    post :unarchive, on: :collection
  end

  # #706 — the nine endpoints of the RESTThreadStore.js contract. The `path` fixes the
  # base URL the store receives (`comments: { url: ... }`); everything else hangs off it
  # exactly as `_buildUrl` builds it. The commentable travels in the query string of that
  # same base, so it reaches all nine without the route declaring it.
  resources :block_editor_threads, path: "block_editor_comments", only: %i[index create update destroy] do
    resources :comments, controller: "block_editor_threads/comments", only: %i[create update destroy] do
      resource :reactions, controller: "block_editor_threads/comments/reactions", only: %i[create destroy]
    end
  end
end
