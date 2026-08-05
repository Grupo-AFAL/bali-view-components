# frozen_string_literal: true

class MoviesController < ApplicationController
  # Pagy 43+ uses Pagy::Method (included in ApplicationController)

  before_action :set_movie, only: %i[show edit update destroy]

  # Sin `index`: el índice canónico de películas es `/admin/movies`. Lo que sigue son las
  # páginas de detalle y de formulario, que Cypress y los previews visitan directo.

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

  # NOTE: quick_search_value helper has been removed.
  # FilterForm now handles search via search_fields parameter.
  # DataTable auto-populates search config from @filter_form.
end
