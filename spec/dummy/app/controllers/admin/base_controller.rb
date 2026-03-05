# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    layout 'admin'

    private

    def drawer_request?
      params[:layout] == "false"
    end
  end
end
