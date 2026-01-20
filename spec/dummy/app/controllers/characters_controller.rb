# frozen_string_literal: true

class CharactersController < ApplicationController
  before_action :set_movie
  before_action :set_character, only: :destroy

  def new
    @character = @movie.characters.build
    render layout: !request.xhr? && params[:layout] != 'false'
  end

  def create
    @character = @movie.characters.build(character_params)
    @character.position = @movie.characters.maximum(:position).to_i + 1

    if @character.save
      respond_to do |format|
        format.html { redirect_to @movie, notice: 'Character added successfully.' }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to @movie, alert: 'Failed to add character.' }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @character.destroy
    respond_to do |format|
      format.html { redirect_to @movie, notice: 'Character removed.' }
      format.turbo_stream
    end
  end

  def sort
    params[:character].each_with_index do |id, index|
      @movie.characters.find(id).update(position: index)
    end

    head :ok
  end

  private

  def set_movie
    @movie = Movie.find(params[:movie_id])
  end

  def set_character
    @character = @movie.characters.find(params[:id])
  end

  def character_params
    params.expect(character: [:name])
  end
end
