module ComponentTestHelpers
  def movie_form_builder
    view_context = ActionController::Base.new.view_context
    Bali::FormBuilder.new('movie', Movie.new, view_context, {})
  end
end
