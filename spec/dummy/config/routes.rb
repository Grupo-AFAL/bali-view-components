# frozen_string_literal: true

Rails.application.routes.draw do
  # Kitchen Sink Demo Routes
  root 'dashboard#index'

  resources :movies do
    collection do
      post :bulk_action
    end
  end

  resource :settings, only: %i[show update]
  get 'landing', to: 'pages#landing'

  # Existing demo routes
  get 'show-content-in-hovercard', to: 'hovercard#show'

  get 'tab1', to: 'tabs#tab1'
  get 'tab2', to: 'tabs#tab2'
  get 'tab3', to: 'tabs#tab3'

  patch 'sortable_list', to: 'sortable_list#update'
  post 'table/bulk_action', to: 'table#bulk_action'

  get 'users', to: 'users#index'

  resources :gantt_chart, only: %i[update]

  mount Lookbook::Engine, at: '/lookbook'
end
