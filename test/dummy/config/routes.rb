# frozen_string_literal: true

Rails.application.routes.draw do
  mount Bali::Engine => '/bali'
end
