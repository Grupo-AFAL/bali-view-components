# frozen_string_literal: true

class MoviesController < ApplicationController
  # Pagy 43+ uses Pagy::Method (included in ApplicationController)

  before_action :set_movie, only: %i[show edit update destroy]

  def index
    # FilterForm handles Ransack search params, sorting, and filter_groups parsing
    # search_fields enables quick text search across multiple columns
    # storage_id enables filter persistence across page visits
    # persist_enabled is controlled by user preference (stored in cookie)
    @filter_form = Bali::FilterForm.new(
      Movie.all,
      params,
      search_fields: %i[name genre tenant_name],
      storage_id: 'movies',
      persist_enabled: cookies['bali_persist_movies'] == '1'
    )

    # Use Pagy for pagination on the filtered/sorted results
    @pagy, @movies = pagy(@filter_form.result.includes(:tenant), items: 10)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @characters = @movie.characters.positioned
  end

  def new
    @movie = Movie.new
  end

  def edit; end

  def create
    @movie = Movie.new(movie_params)

    if @movie.save
      redirect_to @movie, notice: 'Movie was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @movie.update(movie_params)
      redirect_to @movie, notice: 'Movie was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @movie.destroy
    redirect_to movies_url, notice: 'Movie was successfully deleted.'
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
    @available_filter_attributes ||= Movie.filter_attributes
  end

  # NOTE: quick_search_value helper has been removed.
  # FilterForm now handles search via search_fields parameter.
  # DataTable auto-populates search config from @filter_form.
end
