# frozen_string_literal: true

Rails.application.routes.draw do
  # Kitchen Sink Demo Routes
  root 'dashboard#index'

  resources :movies do
    collection do
      post :bulk_action
    end
    resources :characters, only: %i[new create destroy] do
      collection do
        patch :sort
      end
    end
  end

  resources :studios

  resource :settings, only: %i[show update]
  get 'landing', to: 'pages#landing'
  get 'showcase', to: 'pages#showcase'

  # DirectUpload test (form_with url: without model)
  resources :direct_uploads, only: %i[new create]
  get 'sidemenu-example', to: 'pages#sidemenu_example'

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
  post 'table/bulk_action', to: 'table#bulk_action'

  get 'users', to: 'users#index'

  resources :gantt_chart, only: %i[update]

  mount Lookbook::Engine, at: '/lookbook'
end
