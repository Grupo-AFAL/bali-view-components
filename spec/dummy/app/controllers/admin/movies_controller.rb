# frozen_string_literal: true

module Admin
  class MoviesController < BaseController
    before_action :set_movie, only: %i[show edit update destroy]

    def index
      @filter_form = Bali::FilterForm.new(
        Movie.all,
        params,
        search_fields: %i[name genre tenant_name],
        storage_id: 'admin_movies',
        persist_enabled: cookies['bali_persist_admin_movies'] == '1'
      )
      @pagy, @movies = pagy(@filter_form.result.includes(:tenant), items: 10)

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def show
      @characters = @movie.characters
    end

    def new
      @movie = Movie.new
    end

    def edit; end

    def create
      @movie = Movie.new(movie_params)
      if @movie.save
        redirect_to admin_movie_path(@movie), notice: 'Movie was successfully created.'
      else
        render :new, status: :unprocessable_content
      end
    end

    def update
      if @movie.update(movie_params)
        redirect_to admin_movie_path(@movie), notice: 'Movie was successfully updated.'
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @movie.destroy
      redirect_to admin_movies_url, notice: 'Movie was successfully deleted.'
    end

    def bulk_action
      action = params[:bulk_action]
      movie_ids = params[:movie_ids]

      case action
      when 'delete'
        Movie.where(id: movie_ids).destroy_all
        flash.now[:notice] = "#{movie_ids.size} movie(s) deleted."
      when 'mark_done'
        Movie.where(id: movie_ids).update_all(status: :done)
        flash.now[:notice] = "#{movie_ids.size} movie(s) marked as done."
      when 'mark_draft'
        Movie.where(id: movie_ids).update_all(status: :draft)
        flash.now[:notice] = "#{movie_ids.size} movie(s) marked as draft."
      end

      redirect_to admin_movies_path
    end

    private

    def set_movie
      @movie = Movie.find(params[:id])
    end

    def movie_params
      params.expect(movie: %i[
        name genre status tenant_id indie
        synopsis rich_description release_date budget
        contact_email website_url time_zone rating poster
      ])
    end

    helper_method :available_filter_attributes
    def available_filter_attributes
      genres = Movie.distinct.pluck(:genre).compact.sort.map { |g| [ g, g ] }
      studios = Tenant.order(:name).pluck(:name, :id)

      [
        { key: :name, label: 'Name', type: :text },
        { key: :genre, label: 'Genre', type: :select, options: genres },
        { key: :tenant_id, label: 'Studio', type: :select, options: studios },
        { key: :status, label: 'Status', type: :select, options: Movie.statuses.map { |k, _v| [ k.humanize, k ] } },
        { key: :created_at, label: 'Created Date', type: :date },
        { key: :indie, label: 'Indie Film', type: :boolean }
      ]
    end
  end
end
