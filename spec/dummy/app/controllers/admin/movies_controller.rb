# frozen_string_literal: true

module Admin
  class MoviesController < BaseController
    before_action :set_movie, only: %i[show edit update destroy]
    helper_method :available_filter_attributes

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
      @characters = @movie.characters.positioned
      @related_movies = Movie.where(genre: @movie.genre).where.not(id: @movie.id).limit(4)
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

    def available_filter_attributes
      @available_filter_attributes ||= begin
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
end
