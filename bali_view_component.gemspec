# frozen_string_literal: true

require_relative "lib/bali/version"

Gem::Specification.new do |spec|
  spec.name        = "bali_view_components"
  spec.version     = Bali::VERSION
  spec.authors     = [ "Federico Gonzalez", "Miguel Frías" ]
  spec.email       = [ "fedegl@hey.com", "miguelf@enjoykitchen.mx" ]
  spec.homepage    = "https://github.com/Grupo-AFAL/bali-view-components"
  spec.summary     = "Bali ViewComponents — AFAL's Rails UI component library"
  spec.description = "Server-rendered UI component library for Rails: ViewComponent + " \
                     "Stimulus + Tailwind CSS/daisyUI. Ships ~90 components (forms, " \
                     "filters, data tables, overlays, Gantt, block editor) with a " \
                     "FormBuilder, filtering DSL and optional engine controllers."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Grupo-AFAL/bali-view-components"
  spec.metadata["changelog_uri"] = "https://github.com/Grupo-AFAL/bali-view-components/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "caxlsx"
  # Word-level LCS diff for Bali::BlockNote::Diff (MIT, no transitive deps).
  spec.add_dependency "diff-lcs", "~> 1.5"
  # Capped: icon resolution and several legacy spellings ride the alias SVGs
  # lucide-rails still ships, and an uncapped bump that drops them turns those
  # names into IconNotAvailable — a 500 — with no change on the host's side.
  # Raise the cap only after revalidating LucideMapping against the new set.
  spec.add_dependency "lucide-rails", ">= 0.3.0", "< 0.8"
  spec.add_dependency "rails", ">= 8.1", "< 9.0"
  spec.add_dependency "ransack"

  spec.add_dependency "view_component", [ ">= 4.0.0", "< 5.0" ]
  spec.add_dependency "view_component-contrib"

  spec.metadata["rubygems_mfa_required"] = "true"
end
