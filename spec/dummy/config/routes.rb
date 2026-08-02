# frozen_string_literal: true

Rails.application.routes.draw do
  # Marketing / Landing
  root 'dashboard#index'
  get 'landing', to: 'pages#landing'
  get 'showcase', to: 'pages#showcase'
  get 'workspace', to: 'pages#workspace'

  # Auth pages (demo/reference)
  get 'login', to: 'sessions#new'
  get 'register', to: 'sessions#register'
  get 'forgot-password', to: 'sessions#forgot_password', as: :forgot_password
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy'

  # Admin section (AppLayout with sidebar)
  namespace :admin do
    root 'dashboard#index'

    resources :movies do
      resources :characters, only: %i[new create destroy] do
        collection do
          patch :sort
        end
      end
    end

    namespace :movies do
      resource :bulk_actions, only: :create
    end

    resources :studios

    resources :projects, only: %i[index show] do
      resources :tasks, only: :update, module: :projects
    end

    resources :analytics, only: :index
    resources :revenue, only: :index
    resource :settings, only: %i[show update]
  end

  # === Existing routes (keep for Cypress tests) ===
  namespace :movies do
    resource :bulk_actions, only: :create
  end

  resources :movies do
    resources :characters, only: %i[new create destroy] do
      collection do
        patch :sort
      end
    end
  end

  resources :studios
  resource :settings, only: %i[show update]

  # DirectUpload test
  resources :direct_uploads, only: %i[new create]
  get 'sidemenu-example', to: 'pages#sidemenu_example'
  get 'z-stack', to: 'pages#z_stack' # Manual check for the overlay z-index scale
  get 'feedback-widget-demo', to: 'pages#feedback_widget_demo'
  get 'embed/feedback_posts', to: 'pages#feedback_embed' # Stand-in for Opina's embed page

  # Modal/Drawer content routes (for remote loading)
  get 'modals/basic', to: 'modals#basic'
  get 'modals/form', to: 'modals#form'
  get 'modals/confirm', to: 'modals#confirm'
  get 'drawers/user_details', to: 'drawers#user_details'
  get 'drawers/filters', to: 'drawers#filters'
  get 'drawers/order_history', to: 'drawers#order_history'

  # Existing demo routes
  get 'show-content-in-hovercard', to: 'hovercard#show'
  get 'tab1', to: 'tabs#tab1'
  get 'tab2', to: 'tabs#tab2'
  get 'tab3', to: 'tabs#tab3'
  patch 'sortable_list', to: 'sortable_list#update'
  get 'users', to: 'users#index'
  get 'entity_references', to: 'entity_references#index'
  post 'entity_references/resolve', to: 'entity_references#resolve'

  # BlockEditor
  resources :block_editor_threads, path: 'block_editor_comments', only: %i[index create update destroy] do
    resources :comments, controller: 'block_editor_threads/comments', only: %i[create update destroy] do
      resource :reactions, controller: 'block_editor_threads/comments/reactions', only: %i[create destroy]
    end
  end
  post 'block_editor/ai', to: 'block_editor_ai#create'

  # Documents (full editing experience reference)
  # No `edit`: editing a document happens in the overlay `documents#show` opens, not on a
  # page of its own, so `DocumentsController` implements six of the seven actions and the
  # seventh route answered 404 to anyone who followed it.
  resources :documents, except: :edit do
    resources :versions, only: [:index, :show], controller: 'document_versions'
    resources :comment_threads, path: 'comments', controller: 'documents/comment_threads', only: %i[index create update destroy] do
      resources :comments, controller: 'documents/comment_threads/comments', only: %i[create update destroy] do
        resource :reactions, controller: 'documents/comment_threads/comments/reactions', only: %i[create destroy]
      end
    end
    member do
      post :restore_version
    end
  end

  mount Bali::Engine, at: '/bali'
  mount Lookbook::Engine, at: '/lookbook'
end
