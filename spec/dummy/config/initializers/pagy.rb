# frozen_string_literal: true

# Pagy 43+ uses Pagy::OPTIONS instead of Pagy.options
# Note: 'items' was renamed to 'limit' in Pagy 43
Pagy::OPTIONS[:limit] = 10
# Overflow is now built-in, use last_page to redirect out-of-range pages
Pagy::OPTIONS[:overflow] = :last_page

# Load the series helper for Bali::Pagination component
require 'pagy/toolbox/helpers/support/series'
