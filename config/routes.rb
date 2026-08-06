# frozen_string_literal: true

Bali::Engine.routes.draw do
  post 'block_editor/uploads', to: 'block_editor_uploads#create', as: :block_editor_uploads

  # B2 — storage default de las vistas guardadas del DataTable. Sin index/show: las lista
  # el FilterForm. El create recibe el storage_id en el query string de la URL del form.
  resources :saved_views, only: %i[create update destroy]

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
