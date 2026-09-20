# frozen_string_literal: true

# Minimal ActionView::Base subclass for the dummy app helpers directory.
# No longer used in tests — the test suite uses ActionController::Base.new.view_context instead.
class TestHelper < ActionView::Base; end
