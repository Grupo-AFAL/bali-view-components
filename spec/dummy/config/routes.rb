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
      # Fake Gantt schedule endpoints (#705): the executable reference of the
      # mutation contract the island's scheduleClient.js implements. Phase 3
      # (#719) points `mode: :interactive` at these same URLs.
      resource :schedule, only: %i[show update], module: :projects
      resources :dependencies, only: %i[create destroy], module: :projects
    end

    resources :analytics, only: :index
    resources :revenue, only: :index
    resource :settings, only: %i[show update]
  end

  # === Existing routes (keep for Cypress tests) ===
  # Sin `index`: los cuatro índices de referencia viven bajo /admin. Lo que queda acá son las
  # páginas de detalle y de formulario que Cypress y los previews visitan directo.
  resources :movies, except: :index do
    resources :characters, only: %i[new create destroy] do
      collection do
        patch :sort
      end
    end
  end

  resource :settings, only: %i[show update]

  # DirectUpload test
  resources :direct_uploads, only: %i[new create]
  get 'sidemenu-example', to: 'pages#sidemenu_example'
  get 'z-stack', to: 'pages#z_stack' # Manual check for the overlay z-index scale
  get 'feedback-widget-demo', to: 'pages#feedback_widget_demo'
  # SplitView reference page. `?selected=<id>` is the deep link; the Lookbook
  # preview of the component navigates its detail frame here.
  get 'split-view', to: 'split_views#show', as: :split_view
  # `height: :full` needs a bounded parent to fill, so its reference page is the
  # pairing the guide documents: an AppLayout with `viewport_locked: true`.
  get 'split-view/full', to: 'split_views#full', as: :split_view_full
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
  resource :widget_layout, only: :update

  # Scaffolding for `cypress/e2e/modal-history.cy.js`. `modal_redirect#go` exists
  # only to redirect, which is the one condition that sends `ModalController#open`
  # down `_replaceBodyAndURL` — the body-swapping branch whose Back behaviour was
  # previously untested.
  get 'modal_redirect', to: 'modal_redirect#index', as: :modal_redirect
  get 'modal_redirect/go', to: 'modal_redirect#go', as: :modal_redirect_go
  get 'modal_redirect/landing', to: 'modal_redirect#landing', as: :modal_redirect_landing

  # The real widget dashboard demo, as opposed to the Lookbook preview's stub
  # above. A SINGULAR resource — there is one dashboard per user, not a collection.
  # Named `dashboard_widgets` so the path helper keeps that name; the concern
  # itself uses `url_for(action:)` and does not care what this is called.
  resource :dashboard_widgets, only: %i[show create edit update destroy] do
    patch :arrange
  end

  get 'users', to: 'users#index'

  # BlockEditor. Comment threads are NOT here anymore: the engine owns the nine
  # endpoints (`mount Bali::Engine` below), and `config/initializers/bali.rb` says
  # which records may carry threads. That substitution is the adoption test — the
  # dummy consumes the engine the same way a host app does.
  post 'block_editor/ai', to: 'block_editor_ai#create'

  # Documents (full editing experience reference)
  # No `edit`: editing a document happens in the overlay `documents#show` opens, not on a
  # page of its own, so `DocumentsController` implements six of the seven actions and the
  # seventh route answered 404 to anyone who followed it.
  # Las versiones ya NO son rutas de esta app: `versions_url: :auto` en el DocumentEditor
  # apunta a `Bali::ContentVersionsController` del engine montado abajo (#707). Los
  # comentarios tampoco (#706): `comments: { url: :auto, commentable: }` apunta a los
  # nueve endpoints del engine.
  resources :documents, except: :edit

  mount Bali::Engine, at: '/bali'
  mount Lookbook::Engine, at: '/lookbook'
end
