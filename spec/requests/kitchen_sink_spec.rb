# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Kitchen Sink Demo Pages', type: :request do
  describe 'Dashboard' do
    it 'renders the dashboard page successfully' do
      get root_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Movies' do
    let!(:tenant) { Tenant.create!(name: 'Test Studio') }
    let!(:movie) { Movie.create!(name: 'Test Movie', genre: 'Action', status: :draft, tenant: tenant) }

    describe 'GET /movies' do
      it 'renders the index page successfully' do
        get movies_path
        expect(response).to have_http_status(:ok)
      end

      it 'renders with filter params' do
        get movies_path, params: { q: { name_cont: 'Test' } }
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /movies/:id' do
      it 'renders the show page successfully' do
        get movie_path(movie)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /movies/new' do
      it 'renders the new page successfully' do
        get new_movie_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'GET /movies/:id/edit' do
      it 'renders the edit page successfully' do
        get edit_movie_path(movie)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'Settings' do
    describe 'GET /settings' do
      it 'renders the settings page successfully' do
        get settings_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'Landing Page' do
    describe 'GET /landing' do
      it 'renders the landing page successfully' do
        get landing_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
