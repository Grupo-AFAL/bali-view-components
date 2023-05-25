# frozen_string_literal: true

class UsersController < ApplicationController
  def index
    users = [
      { id: 1, full_name: 'John Doe' },
      { id: 2, full_name: 'Jane Doe' },
      { id: 3, full_name: 'John Smith' },
      { id: 4, full_name: 'Jane Smith' },
      { id: 5, full_name: 'John Wayne' },
      { id: 6, full_name: 'Jane Wayne' },
      { id: 7, full_name: 'Chris Doe' },
      { id: 8, full_name: 'Chris Smith' },
      { id: 9, full_name: 'Peter Johnson' },
      { id: 10, full_name: 'Peter Jackson' }
    ]

    render json: users
  end
end
