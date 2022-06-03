# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  get 'show-content-in-hovercard', to: 'hovercard#show' if Rails.env.development?

  mount Lookbook::Engine, at: '/lookbook'
end
