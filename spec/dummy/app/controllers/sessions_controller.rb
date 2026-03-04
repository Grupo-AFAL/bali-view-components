# frozen_string_literal: true

class SessionsController < ApplicationController
  layout 'auth'

  def new
    # Login page
  end

  def create
    # Demo only — redirect back to login with a notice
    redirect_to login_path, notice: 'Demo app — no real authentication configured.'
  end

  def destroy
    redirect_to root_path, notice: 'Signed out successfully.'
  end

  def register
    # Registration page
  end

  def forgot_password
    # Forgot password page
  end
end
