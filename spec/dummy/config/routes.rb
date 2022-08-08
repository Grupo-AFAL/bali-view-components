# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get 'show-content-in-hovercard', to: 'hovercard#show'

  get 'tab1', to: 'tabs#tab1'
  get 'tab2', to: 'tabs#tab2'
  get 'tab3', to: 'tabs#tab3'

  patch 'sortable_list', to: 'sortable_list#update'

  resources :gantt_chart, only: %i[update]

  mount Lookbook::Engine, at: '/lookbook'
end
