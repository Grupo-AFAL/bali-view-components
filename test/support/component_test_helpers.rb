# frozen_string_literal: true

module ComponentTestHelpers
  def movie_form_builder(resource = Movie.new)
    view_context = ActionController::Base.new.view_context
    Bali::FormBuilder.new("movie", resource, view_context, {})
  end
end
