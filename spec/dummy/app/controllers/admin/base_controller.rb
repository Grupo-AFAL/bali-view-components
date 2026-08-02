# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    self.conditional_layout = 'admin'
  end
end
