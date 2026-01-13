# Bali Asset Pipeline Migration Plan

## Overview

**Current Version**: 1.4.23
**Target Version**: 2.0.0
**Migration**: Bulma + Sprockets + dartsass → DaisyUI + Propshaft + Tailwind CSS Rails

This document provides a detailed, step-by-step implementation plan for migrating Bali's asset pipeline from the legacy Bulma/Sprockets setup to a modern Propshaft + Tailwind CSS + DaisyUI architecture.

---

## Table of Contents

1. [Phase 1: Infrastructure Setup](#phase-1-infrastructure-setup)
2. [Phase 2: Remove Legacy Dependencies](#phase-2-remove-legacy-dependencies)
3. [Phase 3: Component Migration Strategy](#phase-3-component-migration-strategy)
4. [Phase 4: JavaScript Simplification](#phase-4-javascript-simplification)
5. [Phase 5: Gem Distribution Setup](#phase-5-gem-distribution-setup)
6. [Phase 6: Consumer Integration Documentation](#phase-6-consumer-integration-documentation)
7. [Appendix: SCSS to Tailwind Mapping](#appendix-scss-to-tailwind-mapping)

---

## Phase 1: Infrastructure Setup

### Duration: 1 sprint
### Risk: Low
### Prerequisites: None

### Step 1.1: Work from Tailwind Migration Branch

All migration work will be done on the existing `tailwind-migration` branch:

```bash
git checkout tailwind-migration
git pull origin tailwind-migration
```

For individual component migrations, create sub-branches:

```bash
git checkout tailwind-migration
git checkout -b migrate/component-name
# ... do work ...
git checkout tailwind-migration
git merge migrate/component-name
```

### Step 1.2: Update Gemfile

```ruby
# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

# === REMOVE THESE ===
# gem 'bulma-rails', '~> 0.9.3'      # REMOVE
# gem 'dartsass-rails'                # REMOVE
# gem 'sprockets-rails'               # REMOVE

# === KEEP/ADD THESE ===
gem 'propshaft'                       # Rails 8 default asset pipeline
gem 'tailwindcss-rails', '~> 4.0'     # Standalone Tailwind (no Node)
gem 'importmap-rails', '~> 2.0'       # ES modules without bundling

# Other dependencies (unchanged)
gem 'caxlsx', '~> 4.1'
gem 'csv'
gem 'device_detector'
gem 'rrule', git: 'https://github.com/square/ruby-rrule'

gem 'lookbook'
gem 'ransack'
gem 'simple_command'
gem 'view_component'
gem 'view_component-contrib'

gem 'debug', '>= 1.0.0'

group :development do
  gem 'puma', '< 7'
  gem 'rubocop', '~> 1', require: false
  gem 'rubocop-rails', '~> 2'
end

group :test do
  gem 'capybara', '~> 3'
  gem 'simplecov', require: false
  gem 'sqlite3', '~> 2.0'
end

group :development, :test do
  gem 'dotenv'
  gem 'rspec-rails', '~> 8'
  gem 'stimulus-rails', '~> 1.3'
  gem 'turbo-rails', '~> 2'
end
```

### Step 1.3: Update Engine Configuration

Replace `lib/bali/engine.rb`:

```ruby
# frozen_string_literal: true

require 'view_component-contrib'

module Bali
  class Engine < ::Rails::Engine
    isolate_namespace Bali

    config.eager_load_paths = %W[
      #{root}/app/components
      #{root}/app/lib
    ]

    overrides = File.expand_path(
      File.join(File.dirname(__FILE__), 'overrides', '**', '*_override.rb')
    )
    config.to_prepare { Dir.glob(overrides).each { |override| load override } }

    config.generators do |g|
      g.test_framework :rspec, fixture: true
      g.view_specs      false
      g.routing_specs   false
      g.helper          false
    end

    ActiveSupport.on_load(:view_component) do
      ViewComponent::Preview.extend ViewComponentContrib::Preview::Sidecarable
      ViewComponent::Preview.extend ViewComponentContrib::Preview::Abstract
    end

    ActiveSupport.on_load(:active_record) do
      include Bali::Concerns::GlobalIdAccessors
    end

    initializer 'Register Bali ActiveModel::Types' do
      ActiveModel::Type.register(:date_range, Bali::Types::DateRangeValue)
    end

    # Propshaft asset paths (simplified from Sprockets)
    initializer 'bali.assets.paths' do |app|
      # Add component paths for JS discovery
      app.config.assets.paths << root.join('app/components')
      app.config.assets.paths << root.join('app/assets/javascripts')
    end

    # Import map pins for Bali controllers
    initializer 'bali.importmap', before: 'importmap' do |app|
      if defined?(Importmap)
        app.config.importmap.paths << root.join('config/importmap.rb')
      end
    end
  end
end
```

### Step 1.4: Create Bali Import Map Configuration

Create `config/importmap.rb` in the gem root:

```ruby
# frozen_string_literal: true

# Bali ViewComponents Import Map
# These pins are automatically added to consumer apps

# Bali Utils
pin 'bali/utils/domHelpers', to: 'bali/utils/domHelpers.js'
pin 'bali/utils/google-maps-loader', to: 'bali/utils/google-maps-loader.js'
pin 'bali/utils/formatters', to: 'bali/utils/formatters.js'
pin 'bali/utils/form', to: 'bali/utils/form.js'
pin 'bali/utils/use-click-outside', to: 'bali/utils/use-click-outside.js'
pin 'bali/utils/time', to: 'bali/utils/time.js'
pin 'bali/utils/use-dispatch', to: 'bali/utils/use-dispatch.js'

# Bali Stimulus Controllers (from app/assets/javascripts)
pin 'bali/auto-play-audio-controller', to: 'bali/controllers/auto-play-audio-controller.js'
pin 'bali/autocomplete-address-controller', to: 'bali/controllers/autocomplete-address-controller.js'
pin 'bali/checkbox-toggle-controller', to: 'bali/controllers/checkbox-toggle-controller.js'
pin 'bali/checkbox-reveal-controller', to: 'bali/controllers/checkbox-reveal-controller.js'
pin 'bali/datepicker-controller', to: 'bali/controllers/datepicker-controller.js'
pin 'bali/drawing-maps-controller', to: 'bali/controllers/drawing-maps-controller.js'
pin 'bali/dynamic-fields-controller', to: 'bali/controllers/dynamic-fields-controller.js'
pin 'bali/elements-overlap-controller', to: 'bali/controllers/elements-overlap-controller.js'
pin 'bali/file-input-controller', to: 'bali/controllers/file-input-controller.js'
pin 'bali/focus-on-connect-controller', to: 'bali/controllers/focus-on-connect-controller.js'
pin 'bali/geocoder-maps-controller', to: 'bali/controllers/geocoder-maps-controller.js'
pin 'bali/input-on-change-controller', to: 'bali/controllers/input-on-change-controller.js'
pin 'bali/interact-controller', to: 'bali/controllers/interact-controller.js'
pin 'bali/print-controller', to: 'bali/controllers/print-controller.js'
pin 'bali/radio-buttons-group-controller', to: 'bali/controllers/radio-buttons-group-controller.js'
pin 'bali/radio-toggle-controller', to: 'bali/controllers/radio-toggle-controller.js'
pin 'bali/slim-select-controller', to: 'bali/controllers/slim-select-controller.js'
pin 'bali/step-number-input-controller', to: 'bali/controllers/step-number-input-controller.js'
pin 'bali/submit-button-controller', to: 'bali/controllers/submit-button-controller.js'
pin 'bali/submit-on-change-controller', to: 'bali/controllers/submit-on-change-controller.js'
pin 'bali/time-period-field-controller', to: 'bali/controllers/time-period-field-controller.js'
pin 'bali/trix-attachments-controller', to: 'bali/controllers/trix-attachments-controller.js'

# Bali Component Controllers (from app/components)
pin 'bali/avatar', to: 'bali/avatar/index.js'
pin 'bali/bulk_actions', to: 'bali/bulk_actions/index.js'
pin 'bali/carousel', to: 'bali/carousel/index.js'
pin 'bali/chart', to: 'bali/chart/index.js'
pin 'bali/clipboard', to: 'bali/clipboard/index.js'
pin 'bali/drawer', to: 'bali/drawer/index.js'
pin 'bali/dropdown', to: 'bali/dropdown/index.js'
pin 'bali/gantt-chart/connection-line', to: 'bali/gantt_chart/connection_line.js'
pin 'bali/gantt-chart/foldable-item', to: 'bali/gantt_chart/gantt_foldable_item.js'
pin 'bali/gantt-chart', to: 'bali/gantt_chart/index.js'
pin 'bali/hovercard', to: 'bali/hover_card/index.js'
pin 'bali/image-field', to: 'bali/image_field/index.js'
pin 'bali/locations_map', to: 'bali/locations_map/index.js'
pin 'bali/modal', to: 'bali/modal/index.js'
pin 'bali/navbar', to: 'bali/navbar/index.js'
pin 'bali/notification', to: 'bali/notification/index.js'
pin 'bali/rate', to: 'bali/rate/index.js'
pin 'bali/reveal', to: 'bali/reveal/index.js'
pin 'bali/side_menu', to: 'bali/side_menu/index.js'
pin 'bali/sortable_list', to: 'bali/sortable_list/index.js'
pin 'bali/table', to: 'bali/table/index.js'
pin 'bali/tabs', to: 'bali/tabs/index.js'
pin 'bali/timeago', to: 'bali/timeago/index.js'
pin 'bali/tooltip', to: 'bali/tooltip/index.js'
pin 'bali/tree_view/item', to: 'bali/tree_view/item/index.js'
pin 'bali/turbo_native_app/sign_out', to: 'bali/turbo_native_app/sign_out/index.js'
pin 'bali/filters/filter-attribute', to: 'bali/filters/controllers/filter-attribute-controller.js'
pin 'bali/filters/filter-text-inputs-manager', to: 'bali/filters/controllers/filter-text-inputs-manager-controller.js'
pin 'bali/filters/filter-form', to: 'bali/filters/controllers/filter-form-controller.js'
pin 'bali/filters/popup', to: 'bali/filters/controllers/popup-controller.js'
pin 'bali/filters/selected', to: 'bali/filters/controllers/selected-controller.js'
pin 'bali/recurrent-event-rule', to: 'bali/recurrent_event_rule_form/index.js'
pin 'bali/rich_text_editor', to: 'bali/rich_text_editor/index.js'
```

### Step 1.5: Update Dummy App Configuration

#### Update `spec/dummy/config/application.rb`:

```ruby
require_relative 'boot'

require 'rails/all'

require 'view_component'

Bundler.require(*Rails.groups)
require 'bali'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    config.action_controller.include_all_helpers = false
    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = 'Tijuana'
    config.generators.system_tests = nil

    # ViewComponents
    config.autoload_paths << Rails.root.parent.parent.join('app/components')
    config.view_component.preview_paths << Rails.root.parent.parent.join('app/components')

    config.lookbook.listen_extensions = %w[js]  # Remove scss
    config.lookbook.preview_layout = 'lookbook_preview'
  end
end
```

#### Update `spec/dummy/Procfile.dev`:

```
web: bin/rails server -p 3001
css: bin/rails tailwindcss:watch
```

#### Update `spec/dummy/app/assets/tailwind/application.css`:

```css
@import "tailwindcss";
@plugin "daisyui" {
  themes: light --default, dark;
}

/* Source paths for Tailwind to scan */
@source "../../../views/**/*.erb";
@source "../../../helpers/**/*.rb";
@source "../../../javascript/**/*.js";
@source "../../../../public/*.html";

/* Bali ViewComponents - scan gem's components */
@source "../../../../../app/components/**/*.{erb,rb}";

/* Custom component styles that can't be expressed in Tailwind */
@source "../../../stylesheets/components/**/*.css";
```

#### Create `spec/dummy/app/assets/config/manifest.js` (Propshaft):

```javascript
// Propshaft manifest - simpler than Sprockets
//= link_tree ../images
//= link_tree ../builds
```

### Step 1.6: Verification Checkpoint

```bash
cd spec/dummy

# Install dependencies
bundle install

# Verify Propshaft is working
bin/rails assets:precompile

# Verify Tailwind is working
bin/rails tailwindcss:build

# Start the server
bin/dev

# Open Lookbook and verify components render
open http://localhost:3001/lookbook
```

**Success criteria:**
- [ ] `bundle install` completes without errors
- [ ] `assets:precompile` succeeds
- [ ] `tailwindcss:build` generates output
- [ ] Lookbook loads (components may look broken - expected at this stage)

---

## Phase 2: Remove Legacy Dependencies

### Duration: 1-2 days
### Risk: Medium
### Prerequisites: Phase 1 complete

### Step 2.1: Remove Bulma

```bash
# Remove bulma-rails gem reference
# Already done in Phase 1 Gemfile update

# Verify no Bulma imports remain
grep -r "bulma" app/
grep -r "@import 'bulma'" spec/dummy/
```

### Step 2.2: Remove dartsass-rails

```bash
# Remove any dartsass configuration
rm -f spec/dummy/config/initializers/dartsass.rb

# Remove sass build command from Procfile (already done in Phase 1)
```

### Step 2.3: Create CSS Variables File

Create `spec/dummy/app/assets/stylesheets/components/variables.css`:

```css
/*
 * Bali CSS Custom Properties
 * These replace SCSS variables from variables.scss
 * DaisyUI provides most colors, these are for custom values
 */

:root {
  /* Custom shadows */
  --bali-shadow: 0px 3px 18px rgba(0, 0, 0, 0.1), 0 0 0 1px rgba(0, 0, 0, 0.03);
  --bali-shadow-thick: 0px 3px 18px rgba(0, 0, 0, 0.1), 0 0 0 8px rgba(0, 0, 0, 0.25);
  --bali-shadow-sharp: 3px 3px 3px rgba(10, 10, 10, 0.1);

  /* Navbar */
  --bali-navbar-height: 3.75rem;

  /* Gantt Chart specific */
  --gantt-header-height: 45px;
  --gantt-row-height: 35px;
  --gantt-list-width: 200px;
  --gantt-item-bubble-height: 25px;
}
```

### Step 2.4: Update Asset Manifest

Delete old Sprockets manifest, keep Propshaft:

```bash
# Remove old Sprockets-style manifest
rm -f app/assets/config/bali_manifest.js

# Keep Propshaft manifest in dummy app
```

### Step 2.5: Remove SCSS Files (Staged)

Create a script to track SCSS files for migration:

```bash
# Create migration tracking file
cat > docs/migration/scss_files_to_migrate.txt << 'EOF'
# SCSS Files to Migrate to Tailwind Classes
# Check off as each file is converted

## High Priority (Core Components)
[ ] app/components/bali/card/index.scss
[ ] app/components/bali/modal/index.scss
[ ] app/components/bali/dropdown/index.scss
[ ] app/components/bali/tabs/index.scss
[ ] app/components/bali/navbar/index.scss
[ ] app/components/bali/notification/index.scss
[ ] app/components/bali/table/index.scss

## Medium Priority (Form Components)
[ ] app/components/bali/filters/index.scss
[ ] app/components/bali/search_input/index.scss
[ ] app/components/bali/image_field/index.scss

## Complex Components (Need Special Handling)
[ ] app/components/bali/gantt_chart/index.scss (+ 6 sub-files)
[ ] app/components/bali/rich_text_editor/index.scss (+ 3 sub-files)
[ ] app/components/bali/calendar/index.scss

## Lower Priority
[ ] app/components/bali/avatar/index.scss
[ ] app/components/bali/bulk_actions/index.scss
[ ] app/components/bali/carousel/index.scss
[ ] app/components/bali/chart/index.scss
[ ] app/components/bali/clipboard/index.scss
[ ] app/components/bali/drawer/index.scss
[ ] app/components/bali/heatmap/index.scss
[ ] app/components/bali/hover_card/index.scss
[ ] app/components/bali/icon/index.scss
[ ] app/components/bali/image_grid/index.scss
[ ] app/components/bali/info_level/index.scss
[ ] app/components/bali/level/index.scss
[ ] app/components/bali/link/index.scss
[ ] app/components/bali/list/index.scss
[ ] app/components/bali/loader/index.scss
[ ] app/components/bali/locations_map/index.scss
[ ] app/components/bali/page_header/index.scss
[ ] app/components/bali/progress/index.scss
[ ] app/components/bali/properties_table/index.scss
[ ] app/components/bali/rate/index.scss
[ ] app/components/bali/recurrent_event_rule_form/index.scss
[ ] app/components/bali/reveal/index.scss
[ ] app/components/bali/side_menu/index.scss
[ ] app/components/bali/sortable_list/index.scss
[ ] app/components/bali/stepper/index.scss
[ ] app/components/bali/timeline/index.scss
[ ] app/components/bali/tooltip/index.scss
[ ] app/components/bali/tree_view/index.scss
[ ] app/components/bali/actions_dropdown/index.scss
[ ] app/components/bali/label_value/index.scss
[ ] app/components/bali/message/index.scss
[ ] app/components/bali/tag/index.scss
EOF
```

### Step 2.6: Verification Checkpoint

```bash
# Verify no SCSS compilation is needed
bin/rails tailwindcss:build

# Check that the app still loads
bin/dev

# Run existing tests (expect some failures)
bundle exec rspec
```

---

## Phase 3: Component Migration Strategy

### Duration: 2-4 sprints (depending on team size)
### Risk: High
### Prerequisites: Phase 2 complete

### Migration Order

Components should be migrated in dependency order:

```
Tier 1 (No dependencies):
├── Icon
├── Link
├── Tag
├── Loader
└── Progress

Tier 2 (Basic layout):
├── Card
├── Modal
├── Dropdown
├── Tabs
└── Avatar

Tier 3 (Form-related):
├── Notification
├── Table
├── Filters
├── SearchInput
└── ImageField

Tier 4 (Complex):
├── Navbar
├── SideMenu
├── Calendar
├── GanttChart (complex - migrate last)
└── RichTextEditor (may need separate handling)
```

### Per-Component Migration Process

For each component, follow this exact process:

#### Step 3.1: Create Component Branch

```bash
git checkout tailwind-migration
git checkout -b migrate/component-name
```

#### Step 3.2: Analyze Current SCSS

Example for Card component:

```bash
# Read current SCSS
cat app/components/bali/card/index.scss

# Current content:
# .card {
#   .alt-image { @apply hidden; }
#   .image-container:hover {
#     .alt-image { @apply block; }
#     .main-image { @apply hidden; }
#   }
# }
```

#### Step 3.3: Convert to Tailwind Classes in ERB

Update `app/components/bali/card/component.html.erb`:

```erb
<%# Before: relied on SCSS for hover behavior %>
<%# After: use Tailwind group utilities %>

<div class="<%= card_classes %> group">
  <% if image? %>
    <div class="relative">
      <%= image %>
      <% if alt_image? %>
        <div class="absolute inset-0 hidden group-hover:block">
          <%= alt_image %>
        </div>
      <% end %>
    </div>
  <% end %>

  <div class="card-body">
    <%= content %>
  </div>
</div>
```

#### Step 3.4: Update Component Ruby Class

Update `app/components/bali/card/component.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Card
    class Component < ApplicationComponent
      renders_one :image
      renders_one :alt_image
      renders_one :header
      renders_one :footer
      renders_many :actions

      # DaisyUI card variants
      VARIANTS = {
        default: '',
        bordered: 'card-bordered',
        compact: 'card-compact',
        side: 'card-side'
      }.freeze

      def initialize(variant: :default, shadow: true, **options)
        @variant = variant
        @shadow = shadow
        @options = options
      end

      private

      def card_classes
        class_names(
          'card',
          'bg-base-100',
          VARIANTS[@variant],
          @shadow ? 'shadow-xl' : nil,
          @options[:class]
        )
      end
    end
  end
end
```

#### Step 3.5: Delete SCSS File

```bash
rm app/components/bali/card/index.scss
```

#### Step 3.6: Update Tests

Update `spec/components/bali/card/component_spec.rb`:

```ruby
RSpec.describe Bali::Card::Component, type: :component do
  it 'renders with default classes' do
    render_inline(described_class.new) { 'Content' }

    expect(page).to have_css('.card.bg-base-100.shadow-xl')
  end

  it 'renders bordered variant' do
    render_inline(described_class.new(variant: :bordered)) { 'Content' }

    expect(page).to have_css('.card.card-bordered')
  end

  it 'renders without shadow when disabled' do
    render_inline(described_class.new(shadow: false)) { 'Content' }

    expect(page).not_to have_css('.shadow-xl')
  end
end
```

#### Step 3.7: Visual Verification

```bash
# Start Lookbook
cd spec/dummy && bin/dev

# Navigate to component
open http://localhost:3001/lookbook/inspect/bali/card/default

# Verify:
# - Component renders correctly
# - No console errors
# - Hover states work
# - All variants display properly
```

#### Step 3.8: Commit and Merge

```bash
git add -A
git commit -m "Migrate Card component from Bulma to DaisyUI

- Replace SCSS with Tailwind utility classes
- Update component.rb with DaisyUI variants
- Remove index.scss file
- Update tests for new class expectations

Verification:
- RSpec: ✓ X examples, 0 failures
- Visual: ✓ Lookbook renders correctly"

git checkout tailwind-migration
git merge migrate/component-name
```

### Special Case: Complex Components

#### Gantt Chart Migration Strategy

The Gantt Chart has significant custom CSS that cannot be replaced with utility classes. Strategy:

1. **Keep a minimal CSS file** for Gantt-specific styles
2. **Convert to CSS custom properties** instead of SCSS variables
3. **Use Tailwind for common utilities**

Create `app/components/bali/gantt_chart/gantt.css`:

```css
/* Gantt Chart - Custom styles that can't be utility classes */

.gantt-chart-component {
  --gantt-header-height: 45px;
  --gantt-row-height: 35px;
  --gantt-list-width: 200px;
  --gantt-border-color: theme('colors.base-300');
  --gantt-today-color: theme('colors.info');

  @apply border-t-2 border-b;
  border-color: var(--gantt-border-color);
}

.gantt-chart-header {
  line-height: var(--gantt-header-height);
  @apply border-r border-l w-full pl-5 text-base-content/70 uppercase;
}

.gantt-chart-today-marker {
  @apply absolute top-0 w-0.5 z-10;
  height: 100%;
  background-color: var(--gantt-today-color);
}

/* ... rest of gantt-specific styles */
```

#### Rich Text Editor Migration Strategy

The Rich Text Editor (TipTap) has its own styling requirements:

1. **Keep content styles** in a CSS file
2. **Convert bubble menu** to Tailwind
3. **Keep syntax highlighting** styles

This component may need to remain as a CSS file that consumers import separately.

---

## Phase 4: JavaScript Simplification

### Duration: 1 sprint
### Risk: Medium
### Prerequisites: Phase 3 substantially complete

### Step 4.1: Audit Current Import Map

Current `spec/dummy/config/importmap.rb` has ~225 pins. Categorize them:

```
Category A - Keep as CDN pins (stable, used by Bali):
- @hotwired/turbo-rails
- @hotwired/stimulus
- chart.js
- flatpickr
- slim-select
- sortablejs
- tippy.js
- date-fns
- lodash.throttle/debounce

Category B - Rich Text Editor (50+ pins):
- @tiptap/* (30+ packages)
- prosemirror-* (20+ packages)
- Decision: Either keep or make optional

Category C - Bali internal (auto-discovered):
- bali/controllers/*
- bali/components/*
- bali/utils/*
```

### Step 4.2: Create Simplified Import Map

Update `spec/dummy/config/importmap.rb`:

```ruby
# Pin npm packages by running ./bin/importmap

pin 'application'

# === Rails Core ===
pin '@rails/actioncable', to: 'actioncable.esm.js'
pin '@rails/activestorage', to: 'activestorage.esm.js'
pin '@rails/actiontext', to: 'actiontext.esm.js'
pin '@rails/request.js', to: 'https://cdn.jsdelivr.net/npm/@rails/request.js@0.0.12/+esm'

# === Hotwired ===
pin '@hotwired/turbo-rails', to: 'https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.16/+esm'
pin '@hotwired/stimulus', to: 'stimulus.min.js'
pin '@hotwired/stimulus-loading', to: 'stimulus-loading.js'

# === Application Controllers ===
pin_all_from 'app/javascript/controllers', under: 'controllers'

# === Third-party Libraries ===
pin 'chart.js', to: 'https://cdn.jsdelivr.net/npm/chart.js@4.5.0/+esm'
pin 'flatpickr', to: 'https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/+esm'
pin 'flatpickr/dist/l10n/es.js', to: 'https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/l10n/es.js'
pin 'slim-select', to: 'https://cdn.jsdelivr.net/npm/slim-select@2.12.1/+esm'
pin 'sortablejs', to: 'https://cdn.jsdelivr.net/npm/sortablejs@1.15.6/+esm'
pin 'tippy.js', to: 'https://cdn.jsdelivr.net/npm/tippy.js@6.3.7/+esm'
pin '@popperjs/core', to: 'https://cdn.jsdelivr.net/npm/@popperjs/core@2.11.8/+esm'
pin 'date-fns', to: 'https://cdn.jsdelivr.net/npm/date-fns@4.1.0/+esm'
pin 'date-fns/locale/en-US', to: 'https://cdn.jsdelivr.net/npm/date-fns@4.1.0/locale/en-US/+esm'
pin 'date-fns/locale/es', to: 'https://cdn.jsdelivr.net/npm/date-fns@4.1.0/locale/es/+esm'
pin 'lodash.throttle', to: 'https://cdn.jsdelivr.net/npm/lodash.throttle@4.1.1/+esm'
pin 'lodash.debounce', to: 'https://cdn.jsdelivr.net/npm/lodash.debounce@4.0.8/+esm'
pin '@googlemaps/markerclusterer', to: 'https://cdn.jsdelivr.net/npm/@googlemaps/markerclusterer@2.6.2/+esm'

# === Bali Components (auto-loaded from gem) ===
# These are defined in the gem's config/importmap.rb and merged automatically
```

### Step 4.3: Rich Text Editor Decision

**Option A: Keep as optional feature**

Create `config/importmap/rich_text_editor.rb`:

```ruby
# Optional: Rich Text Editor pins
# Include this in your importmap if you use Bali::RichTextEditor

pin 'bali/rich_text_editor', to: 'bali/rich_text_editor/index.js'
# ... all tiptap/prosemirror pins
```

**Option B: Recommend bundler for RTE users**

Document that apps using Rich Text Editor should use jsbundling-rails:

```markdown
## Rich Text Editor Setup

The Rich Text Editor component requires TipTap, which has many dependencies.

For apps using importmaps: Add the optional RTE importmap pins (see docs).
For apps using a bundler: `npm install @grupoafal/bali` includes all dependencies.
```

### Step 4.4: Create Bali Controller Registration Helper

Create `app/assets/javascripts/bali/index.js`:

```javascript
// Bali ViewComponents - Controller Registration Helper

export * from './avatar/index.js'
export * from './bulk_actions/index.js'
export * from './carousel/index.js'
export * from './chart/index.js'
export * from './clipboard/index.js'
export * from './drawer/index.js'
export * from './dropdown/index.js'
export * from './gantt_chart/index.js'
export * from './hover_card/index.js'
export * from './image_field/index.js'
export * from './locations_map/index.js'
export * from './modal/index.js'
export * from './navbar/index.js'
export * from './notification/index.js'
export * from './rate/index.js'
export * from './reveal/index.js'
export * from './side_menu/index.js'
export * from './sortable_list/index.js'
export * from './table/index.js'
export * from './tabs/index.js'
export * from './timeago/index.js'
export * from './tooltip/index.js'
export * from './tree_view/item/index.js'
export * from './turbo_native_app/sign_out/index.js'
export * from './filters/controllers/filter-attribute-controller.js'
export * from './filters/controllers/filter-text-inputs-manager-controller.js'
export * from './filters/controllers/filter-form-controller.js'
export * from './filters/controllers/popup-controller.js'
export * from './filters/controllers/selected-controller.js'

// Helper to register all Bali controllers
export function registerBaliControllers(application) {
  // This will be populated by the build process
  // Or consumers can import individual controllers
}
```

---

## Phase 5: Gem Distribution Setup

### Duration: 1 sprint
### Risk: Low
### Prerequisites: Phase 4 complete

### Step 5.1: Update Gemspec

Update `bali_view_component.gemspec`:

```ruby
# frozen_string_literal: true

require_relative 'lib/bali/version'

Gem::Specification.new do |spec|
  spec.name        = 'bali_view_components'
  spec.version     = Bali::VERSION
  spec.authors     = ['Federico Gonzalez', 'Miguel Frías']
  spec.email       = ['fedegl@hey.com', 'miguelf@enjoykitchen.mx']
  spec.homepage    = 'https://github.com/Grupo-AFAL/bali'
  spec.summary     = 'DaisyUI-based ViewComponents for Rails'
  spec.description = 'A collection of 40+ ViewComponents built with Tailwind CSS and DaisyUI'
  spec.license     = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Grupo-AFAL/bali'
  spec.metadata['changelog_uri'] = 'https://github.com/Grupo-AFAL/bali/blob/main/CHANGELOG.md'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  # Core dependencies
  spec.add_dependency 'rails', '>= 7.1', '< 9.0'
  spec.add_dependency 'propshaft'  # Or allow sprockets for backwards compat
  spec.add_dependency 'view_component', ['>= 3.0.0', '< 4.0']
  spec.add_dependency 'view_component-contrib'

  # Optional dependencies (not required)
  # spec.add_dependency 'tailwindcss-rails'  # Consumer provides this

  # Utility dependencies
  spec.add_dependency 'caxlsx'
  spec.add_dependency 'ransack'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
```

### Step 5.2: Create npm Package

Create `package.json` in gem root:

```json
{
  "name": "@grupoafal/bali",
  "version": "2.0.0",
  "description": "DaisyUI-based ViewComponents for Rails - JavaScript Controllers",
  "repository": {
    "type": "git",
    "url": "git+https://github.com/Grupo-AFAL/bali.git"
  },
  "author": "Grupo AFAL",
  "license": "MIT",
  "main": "app/assets/javascripts/bali/index.js",
  "module": "app/assets/javascripts/bali/index.js",
  "type": "module",
  "exports": {
    ".": "./app/assets/javascripts/bali/index.js",
    "./controllers/*": "./app/assets/javascripts/bali/controllers/*.js",
    "./components/*": "./app/components/bali/*/index.js"
  },
  "files": [
    "app/assets/javascripts/bali/**/*.js",
    "app/components/bali/**/index.js"
  ],
  "peerDependencies": {
    "@hotwired/stimulus": "^3.0.0"
  },
  "devDependencies": {
    "cypress": "^13.6.4",
    "playwright": "^1.57.0"
  },
  "keywords": [
    "rails",
    "viewcomponent",
    "daisyui",
    "tailwind",
    "stimulus"
  ]
}
```

### Step 5.3: Create Installation Generator

Create `lib/generators/bali/install/install_generator.rb`:

```ruby
# frozen_string_literal: true

module Bali
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Install Bali ViewComponents'

      def add_tailwind_content_paths
        say_status :info, 'Adding Bali paths to Tailwind content config'

        tailwind_config = 'app/assets/tailwind/application.css'

        if File.exist?(tailwind_config)
          inject_into_file tailwind_config, after: "@import \"tailwindcss\";\n" do
            <<~CSS

              /* Bali ViewComponents */
              @source "../../vendor/bundle/**/bali/**/components/**/*.{erb,rb}";
            CSS
          end
        else
          say_status :warning, 'Tailwind config not found. Please add Bali paths manually.'
        end
      end

      def add_importmap_pins
        return unless File.exist?('config/importmap.rb')

        say_status :info, 'Bali import map pins are auto-loaded from the gem'
      end

      def show_post_install_message
        say_status :success, 'Bali ViewComponents installed!'
        say ''
        say 'Next steps:'
        say '1. Ensure you have tailwindcss-rails and daisyui installed'
        say '2. Add Bali component paths to your Tailwind content config'
        say '3. Import Bali controllers in your application.js'
        say ''
        say 'See https://github.com/Grupo-AFAL/bali for full documentation'
      end
    end
  end
end
```

### Step 5.4: Version Bump

Update `lib/bali/version.rb`:

```ruby
# frozen_string_literal: true

module Bali
  VERSION = '2.0.0'
end
```

---

## Phase 6: Consumer Integration Documentation

### Duration: 1 sprint
### Risk: Low
### Prerequisites: All other phases complete

### Step 6.1: Update README.md

```markdown
# Bali ViewComponents

A collection of 40+ ViewComponents built with Tailwind CSS and DaisyUI for Rails applications.

## Requirements

- Ruby >= 3.1
- Rails >= 7.1
- Tailwind CSS >= 4.0
- DaisyUI >= 5.0

## Installation

### Step 1: Add the gem

```ruby
# Gemfile
gem 'bali_view_components', '~> 2.0'
```

### Step 2: Install Tailwind CSS and DaisyUI

```bash
# If not already installed
bundle add tailwindcss-rails
bin/rails tailwindcss:install

# Add DaisyUI
npm install daisyui
# Or add to your Tailwind config if using CDN
```

### Step 3: Configure Tailwind to scan Bali components

```css
/* app/assets/tailwind/application.css */
@import "tailwindcss";
@plugin "daisyui";

/* Add Bali component paths */
@source "../../vendor/bundle/**/bali/**/components/**/*.{erb,rb}";
```

### Step 4: Import Bali JavaScript controllers

#### Option A: Import Maps (recommended for most apps)

Bali's import map pins are automatically loaded. In your `application.js`:

```javascript
import { application } from "controllers/application"

// Import individual controllers you need
import { ModalController } from "bali/modal"
import { DropdownController } from "bali/dropdown"
import { TabsController } from "bali/tabs"

application.register("modal", ModalController)
application.register("dropdown", DropdownController)
application.register("tabs", TabsController)
```

#### Option B: Node.js bundler (esbuild/Vite)

```bash
npm install @grupoafal/bali
```

```javascript
// application.js
import { application } from "./application"
import * as Bali from "@grupoafal/bali"

// Register all controllers
Object.entries(Bali).forEach(([name, controller]) => {
  if (name.endsWith('Controller')) {
    const identifier = name.replace('Controller', '').toLowerCase()
    application.register(identifier, controller)
  }
})
```

## Usage

```erb
<%# app/views/posts/index.html.erb %>

<%= render Bali::Card::Component.new(variant: :bordered) do |card| %>
  <% card.with_header do %>
    <h2 class="card-title">My Card</h2>
  <% end %>

  <p>Card content goes here</p>

  <% card.with_footer do %>
    <%= render Bali::Button::Component.new(variant: :primary) { "Save" } %>
  <% end %>
<% end %>
```

## Upgrading from v1.x (Bulma)

See [UPGRADING.md](UPGRADING.md) for migration guide from Bulma to DaisyUI.

## Components

| Component | Description |
|-----------|-------------|
| Button | DaisyUI buttons with variants |
| Card | Content cards with slots |
| Modal | Dialog modals |
| Dropdown | Dropdown menus |
| Tabs | Tab navigation |
| Table | Data tables with sorting |
| ... | See full list in docs |

## Development

```bash
# Clone the repo
git clone https://github.com/Grupo-AFAL/bali.git
cd bali

# Install dependencies
bundle install

# Start Lookbook
cd spec/dummy && bin/dev

# Run tests
bundle exec rspec
```

## License

MIT
```

### Step 6.2: Create UPGRADING.md

```markdown
# Upgrading from Bali 1.x to 2.0

Bali 2.0 replaces Bulma CSS with Tailwind CSS + DaisyUI. This is a breaking change.

## Breaking Changes

### CSS Framework

- **Before**: Bulma classes (`is-primary`, `is-large`, `columns`)
- **After**: DaisyUI classes (`btn-primary`, `btn-lg`, `grid`)

### Asset Pipeline

- **Before**: Sprockets + dartsass-rails
- **After**: Propshaft + tailwindcss-rails (or any bundler)

### Removed Dependencies

- `bulma-rails`
- `dartsass-rails`
- `sprockets-rails` (optional, Propshaft recommended)

## Migration Steps

### 1. Update your Gemfile

```ruby
# Remove
gem 'bulma-rails'

# Update
gem 'bali_view_components', '~> 2.0'
gem 'tailwindcss-rails', '~> 4.0'
```

### 2. Install Tailwind CSS

```bash
bin/rails tailwindcss:install
```

### 3. Add DaisyUI

```bash
npm install daisyui
```

### 4. Update your CSS

```css
/* app/assets/tailwind/application.css */
@import "tailwindcss";
@plugin "daisyui";

@source "../../vendor/bundle/**/bali/**/components/**/*.{erb,rb}";
```

### 5. Update custom component usage

If you extended Bali components or used Bulma classes directly:

| Bulma | DaisyUI |
|-------|---------|
| `is-primary` | `btn-primary` |
| `is-danger` | `btn-error` |
| `is-small` | `btn-sm` |
| `is-large` | `btn-lg` |
| `columns` | `grid grid-cols-12` |
| `column is-6` | `col-span-6` |
| `notification` | `alert` |
| `card-content` | `card-body` |

See [docs/reference/daisyui-mapping.md](docs/reference/daisyui-mapping.md) for complete mapping.

### 6. Test thoroughly

```bash
bundle exec rspec
bin/rails test:system
```

## Getting Help

- [GitHub Issues](https://github.com/Grupo-AFAL/bali/issues)
- [DaisyUI Documentation](https://daisyui.com)
- [Tailwind CSS Documentation](https://tailwindcss.com)
```

---

## Appendix: SCSS to Tailwind Mapping

### Color Variables

| SCSS Variable | Tailwind/DaisyUI |
|---------------|------------------|
| `$black` | `text-base-content` |
| `$grey-dark` | `text-base-content/70` |
| `$grey` | `text-base-content/50` |
| `$grey-light` | `text-base-content/30` |
| `$white` | `bg-base-100` |
| `$white-ter` | `bg-base-200` |
| `$white-bis` | `bg-base-300` |
| `$green` | `text-success` |
| `$error` | `text-error` |
| `$purple` | `text-primary` |
| `$blue` | `text-info` |
| `$red` | `text-error` |

### Bulma Mixins

| Bulma Mixin | Tailwind |
|-------------|----------|
| `@include touch` | `max-md:` or `@media (max-width: 768px)` |
| `@include desktop` | `md:` or `@media (min-width: 769px)` |
| `@include tablet` | `sm:` |

### Common Patterns

| SCSS | Tailwind |
|------|----------|
| `margin-left: 0` | `ml-0` |
| `padding: 0.75rem` | `p-3` |
| `font-size: 0.87rem` | `text-sm` |
| `border-radius: 0.25rem` | `rounded` |
| `display: flex` | `flex` |
| `align-items: center` | `items-center` |
| `position: absolute` | `absolute` |
| `z-index: 2` | `z-20` |

### Box Shadow

| SCSS | CSS Custom Property |
|------|---------------------|
| `$box-shadow` | `var(--bali-shadow)` or `shadow-lg` |
| `$thick-box-shadow` | `var(--bali-shadow-thick)` |

---

## Timeline Summary

| Phase | Duration | Description |
|-------|----------|-------------|
| Phase 1 | 1 sprint | Infrastructure setup |
| Phase 2 | 1-2 days | Remove legacy deps |
| Phase 3 | 2-4 sprints | Component migration |
| Phase 4 | 1 sprint | JS simplification |
| Phase 5 | 1 sprint | Distribution setup |
| Phase 6 | 1 sprint | Documentation |

**Total estimated time**: 5-8 sprints depending on team size and component complexity.

---

## Success Criteria

- [ ] All 55 SCSS files removed or converted to minimal CSS
- [ ] All components render correctly in Lookbook
- [ ] All RSpec tests passing
- [ ] Cypress tests passing
- [ ] Gem publishable to RubyGems
- [ ] npm package publishable
- [ ] Consumer integration documented and tested
- [ ] No Bulma or Sprockets dependencies
- [ ] `bin/dev` starts with only 2 processes (web + css)
