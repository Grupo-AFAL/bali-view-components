# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get 'show-content-in-hovercard', to: 'hovercard#show'

  mount Lookbook::Engine, at: '/lookbook'
end
