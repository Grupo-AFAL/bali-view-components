# frozen_string_literal: true

# Pagy 43+ uses Pagy.options instead of Pagy::DEFAULT
# Note: 'items' was renamed to 'limit' in Pagy 43
Pagy.options[:limit] = 10
# Overflow is now built-in, use last_page to redirect out-of-range pages
Pagy.options[:overflow] = :last_page

# Load the series helper for Bali::Pagination component
require 'pagy/toolbox/helpers/support/series'
