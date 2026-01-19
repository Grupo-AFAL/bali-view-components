# frozen_string_literal: true

class PagesController < ApplicationController
  layout 'marketing'

  def landing
    # Stats for marketing page
    @movies_count = Movie.count
    @studios_count = Tenant.count
  end
end
