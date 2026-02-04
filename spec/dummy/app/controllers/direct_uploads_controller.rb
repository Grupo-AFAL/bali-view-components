# frozen_string_literal: true

# Controller for testing DirectUpload component without a model.
# Validates that field names are generated correctly when using form_with url:
class DirectUploadsController < ApplicationController
  def new
    # Renders form for testing DirectUpload without model
  end

  def create
    @field_names = params.keys.sort
    @evidences = params[:evidences]

    respond_to do |format|
      format.turbo_stream
      format.html { render :result }
    end
  end
end
