# frozen_string_literal: true

require "test_helper"

class KitchenSinkDemoPagesTest < ActionDispatch::IntegrationTest
  def setup
    @tenant = Tenant.create!(name: "Test Studio")
    @movie = @tenant.movies.create!(name: "Test Movie", status: 0)
  end


  def movie
    @movie
  end
  #

  def test_dashboard_renders_the_dashboard_page_successfully
    get root_path
    assert_response :ok
  end


  #


  #

  def test_movies_get_movies_renders_the_index_page_successfully
    get movies_path
    assert_response :ok
  end



  def test_movies_get_movies_renders_with_filter_params
    get movies_path, params: { q: { name_cont: "Test" } }
    assert_response :ok
  end


  #

  def test_movies_get_movies_id_renders_the_show_page_successfully
    get movie_path(movie)
    assert_response :ok
  end


  #

  def test_movies_get_movies_new_renders_the_new_page_successfully
    get new_movie_path
    assert_response :ok
  end


  #

  def test_movies_get_movies_id_edit_renders_the_edit_page_successfully
    get edit_movie_path(movie)
    assert_response :ok
  end


  #

  #

  def test_settings_get_settings_renders_the_settings_page_successfully
    get settings_path
    assert_response :ok
  end


  #

  #

  def test_landing_page_get_landing_renders_the_landing_page_successfully
    get landing_path
    assert_response :ok
  end
end
