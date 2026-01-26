# frozen_string_literal: true

# Configure lucide-rails default options
# These will be applied to all lucide_icon calls unless overridden
LucideRails.default_options = LucideRails.default_options.merge(
  'class' => 'lucide-icon',
  'stroke-width' => '2',
  'aria-hidden' => 'true'
)
