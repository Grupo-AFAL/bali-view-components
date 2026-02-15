# frozen_string_literal: true

class UsersController < ApplicationController
  USERS = [
    { id: 1, name: 'John Doe', full_name: 'John Doe' },
    { id: 2, name: 'Jane Doe', full_name: 'Jane Doe' },
    { id: 3, name: 'John Smith', full_name: 'John Smith' },
    { id: 4, name: 'Jane Smith', full_name: 'Jane Smith' },
    { id: 5, name: 'John Wayne', full_name: 'John Wayne' },
    { id: 6, name: 'Jane Wayne', full_name: 'Jane Wayne' },
    { id: 7, name: 'Chris Doe', full_name: 'Chris Doe' },
    { id: 8, name: 'Chris Smith', full_name: 'Chris Smith' },
    { id: 9, name: 'Peter Johnson', full_name: 'Peter Johnson' },
    { id: 10, name: 'Peter Jackson', full_name: 'Peter Jackson' }
  ].freeze

  def index
    users = USERS
    if params[:q].present?
      query = params[:q].downcase
      users = users.select { |u| u[:name].downcase.include?(query) }
    end

    render json: users
  end
end
