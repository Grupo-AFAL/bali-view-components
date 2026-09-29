# frozen_string_literal: true

puts "Creating seed data..."

# Create tenants
tenants = []
['Warner Bros', 'Universal', 'Paramount', 'Disney', 'A24'].each do |name|
  tenants << Tenant.find_or_create_by!(name: name)
end

puts "Created #{tenants.size} tenants"

# Create movies
# A24 films (tenants[4]) are indie, major studios are not
movies_data = [
  { name: 'The Dark Knight', genre: 'Action', status: :done, tenant: tenants[0], indie: false, budget: 185_000_000 },
  { name: 'Inception', genre: 'Sci-Fi', status: :done, tenant: tenants[0], indie: false, budget: 160_000_000 },
  { name: 'Interstellar', genre: 'Sci-Fi', status: :done, tenant: tenants[1], indie: false, budget: 165_000_000 },
  { name: 'Jurassic Park', genre: 'Adventure', status: :done, tenant: tenants[1], indie: false, budget: 63_000_000 },
  { name: 'The Godfather', genre: 'Drama', status: :done, tenant: tenants[2], indie: false, budget: 6_000_000 },
  { name: 'Forrest Gump', genre: 'Drama', status: :done, tenant: tenants[2], indie: false, budget: 55_000_000 },
  { name: 'Top Gun: Maverick', genre: 'Action', status: :done, tenant: tenants[2], indie: false, budget: 170_000_000 },
  { name: 'The Avengers', genre: 'Action', status: :done, tenant: tenants[3], indie: false, budget: 220_000_000 },
  { name: 'Frozen', genre: 'Animation', status: :done, tenant: tenants[3], indie: false, budget: 150_000_000 },
  { name: 'The Lion King', genre: 'Animation', status: :done, tenant: tenants[3], indie: false, budget: 260_000_000 },
  { name: 'Everything Everywhere All at Once', genre: 'Sci-Fi', status: :done, tenant: tenants[4], indie: true, budget: 25_000_000 },
  { name: 'Moonlight', genre: 'Drama', status: :done, tenant: tenants[4], indie: true, budget: 4_000_000 },
  { name: 'Lady Bird', genre: 'Comedy', status: :done, tenant: tenants[4], indie: true, budget: 10_000_000 },
  { name: 'Hereditary', genre: 'Horror', status: :done, tenant: tenants[4], indie: true, budget: 10_000_000 },
  { name: 'Midsommar', genre: 'Horror', status: :done, tenant: tenants[4], indie: true, budget: 9_000_000 },
  { name: 'Untitled Project 1', genre: 'Drama', status: :draft, tenant: tenants[0], indie: false, budget: 80_000_000 },
  { name: 'Untitled Project 2', genre: 'Action', status: :draft, tenant: tenants[1], indie: false, budget: 120_000_000 },
  { name: 'Untitled Project 3', genre: 'Comedy', status: :draft, tenant: tenants[2], indie: true, budget: 15_000_000 },
  { name: 'The Matrix Resurrections', genre: 'Sci-Fi', status: :done, tenant: tenants[0], indie: false, budget: 190_000_000 },
  { name: 'Dune', genre: 'Sci-Fi', status: :done, tenant: tenants[0], indie: false, budget: 165_000_000 }
]

movies_data.each_with_index do |data, index|
  movie = Movie.find_or_initialize_by(name: data[:name])
  # Spread movies across the last 2 years with varied dates
  days_ago = (index * 37) % 730 # Spread across ~2 years
  # Production windows straddling today, so the calendar view of the listing has
  # something to draw around the current month.
  starts_on = Date.current - (60 - (index * 11)).days
  movie.update!(
    genre: data[:genre],
    status: data[:status],
    studio: data[:tenant],
    indie: data[:indie],
    budget: data[:budget],
    created_at: days_ago.days.ago,
    production_starts_on: starts_on,
    production_ends_on: starts_on + (30 + ((index % 5) * 15)).days
  )
end

puts "Created #{Movie.count} movies"

# Create studios for SimpleFilters showcase
studios_data = [
  { name: 'Warner Bros Pictures', country: 'USA', status: :active, size: 'enterprise', founded_year: 1923 },
  { name: 'Universal Pictures', country: 'USA', status: :active, size: 'enterprise', founded_year: 1912 },
  { name: 'Paramount Pictures', country: 'USA', status: :active, size: 'enterprise', founded_year: 1912 },
  { name: 'Walt Disney Studios', country: 'USA', status: :active, size: 'enterprise', founded_year: 1923 },
  { name: 'A24', country: 'USA', status: :active, size: 'medium', founded_year: 2012 },
  { name: 'Studio Ghibli', country: 'Japan', status: :active, size: 'medium', founded_year: 1985 },
  { name: 'Toho', country: 'Japan', status: :active, size: 'large', founded_year: 1932 },
  { name: 'Pinewood Studios', country: 'UK', status: :active, size: 'large', founded_year: 1936 },
  { name: 'Working Title Films', country: 'UK', status: :active, size: 'medium', founded_year: 1983 },
  { name: 'Gaumont', country: 'France', status: :active, size: 'large', founded_year: 1895 },
  { name: 'Pathe', country: 'France', status: :active, size: 'large', founded_year: 1896 },
  { name: 'Bavaria Film', country: 'Germany', status: :active, size: 'medium', founded_year: 1919 },
  { name: 'Constantin Film', country: 'Germany', status: :active, size: 'medium', founded_year: 1950 },
  { name: 'Yash Raj Films', country: 'India', status: :active, size: 'large', founded_year: 1970 },
  { name: 'Dharma Productions', country: 'India', status: :active, size: 'medium', founded_year: 1976 },
  { name: 'Village Roadshow', country: 'Australia', status: :active, size: 'medium', founded_year: 1954 },
  { name: 'Entertainment One', country: 'Canada', status: :inactive, size: 'large', founded_year: 1973 },
  { name: 'Lionsgate Films', country: 'Canada', status: :active, size: 'large', founded_year: 1997 },
  { name: 'Blumhouse Productions', country: 'USA', status: :active, size: 'medium', founded_year: 2000 },
  { name: 'Legendary Pictures', country: 'USA', status: :active, size: 'large', founded_year: 2000 },
  { name: 'New Line Cinema', country: 'USA', status: :pending, size: 'large', founded_year: 1967 },
  { name: 'Focus Features', country: 'USA', status: :active, size: 'medium', founded_year: 2002 },
  { name: 'Searchlight Pictures', country: 'USA', status: :active, size: 'medium', founded_year: 1994 },
  { name: 'Hammer Films', country: 'UK', status: :inactive, size: 'small', founded_year: 1934 },
  { name: 'Film4 Productions', country: 'UK', status: :active, size: 'small', founded_year: 1982 }
]

studios_data.each do |data|
  Studio.find_or_create_by!(name: data[:name]) do |studio|
    studio.country = data[:country]
    studio.status = data[:status]
    studio.size = data[:size]
    studio.founded_year = data[:founded_year]
  end
end

puts "Created #{Studio.count} studios"

# Create documents
sample_content = [
  {
    "id" => "intro-1",
    "type" => "heading",
    "props" => { "level" => 1 },
    "content" => [{ "type" => "text", "text" => "Project Overview" }]
  },
  {
    "id" => "para-1",
    "type" => "paragraph",
    "content" => [
      { "type" => "text", "text" => "This document outlines the key objectives and milestones for the upcoming quarter. Our team has been working diligently on several initiatives that will significantly impact our product roadmap." }
    ]
  },
  {
    "id" => "heading-2",
    "type" => "heading",
    "props" => { "level" => 2 },
    "content" => [{ "type" => "text", "text" => "Key Objectives" }]
  },
  {
    "id" => "para-2",
    "type" => "paragraph",
    "content" => [
      { "type" => "text", "text" => "The primary focus areas include improving user onboarding, enhancing the reporting dashboard, and launching the new API integration platform. Each initiative has dedicated teams and clear success metrics." }
    ]
  },
  {
    "id" => "heading-3",
    "type" => "heading",
    "props" => { "level" => 2 },
    "content" => [{ "type" => "text", "text" => "Timeline & Milestones" }]
  },
  {
    "id" => "para-3",
    "type" => "paragraph",
    "content" => [
      { "type" => "text", "text" => "Phase 1 is expected to complete by end of April, with Phase 2 beginning in May. The full rollout is targeted for July, pending successful beta testing with our early adopter group." }
    ]
  },
  {
    "id" => "heading-4",
    "type" => "heading",
    "props" => { "level" => 2 },
    "content" => [{ "type" => "text", "text" => "Resource Allocation" }]
  },
  {
    "id" => "para-4",
    "type" => "paragraph",
    "content" => [
      { "type" => "text", "text" => "We have allocated additional engineering resources to ensure timely delivery. The design team will be conducting user research sessions throughout the quarter to validate our assumptions and iterate on the experience." }
    ]
  }
]

documents_data = [
  { title: "Q2 2026 Product Roadmap", status: :published, author_name: "Demo User", content: sample_content },
  { title: "Engineering Standards Guide", status: :published, author_name: "Jane Smith", content: sample_content },
  { title: "API Integration Spec", status: :draft, author_name: "Bob Wilson", content: sample_content },
  { title: "User Research Findings", status: :draft, author_name: "Demo User", content: [] },
  { title: "Archived: Legacy Migration Plan", status: :archived, author_name: "Jane Smith", content: sample_content }
]

documents_data.each do |data|
  doc = Document.find_or_initialize_by(title: data[:title])
  doc.update!(
    status: data[:status],
    author_name: data[:author_name],
    content: data[:content]
  )

  if doc.content_versions.empty?
    doc.create_version!(author_name: data[:author_name], summary: "Initial draft")
    doc.create_version!(author_name: data[:author_name], summary: "Added key sections")
    doc.create_version!(author_name: "Jane Smith", summary: "Reviewed and edited") if data[:status].to_s == "published"
  end
end

puts "Created #{Document.count} documents with #{Bali::ContentVersion.count} versions"

# Create projects and tasks for Kanban demo
project = Project.find_or_create_by!(name: "Bali Component Library") do |p|
  p.description = "Open-source ViewComponent library for Rails applications"
end

# Schedule fields (phase/dates/milestone/percent_complete) feed the Bali::Gantt
# timeline at /admin/projects/:id?view=timeline (#704). Dates are relative to
# Date.current so the today marker always lands inside the window; tasks without
# dates exercise the "No dates" section on purpose.
today = Date.current
tasks_data = [
  { title: "Audit existing icon usage", description: "Map all icon names used across AFAL apps", status: :done, priority: :low, position: 0,
    phase: "Foundations", start_date: today - 60, due_date: today - 50, percent_complete: 100 },
  { title: "Migrate to Lucide icons", description: "Replace custom SVGs with Lucide equivalents", status: :done, priority: :medium, position: 1,
    phase: "Foundations", start_date: today - 49, due_date: today - 35, percent_complete: 100 },
  { title: "Upgrade to daisyUI 5", description: "Update class names and verify all component previews", status: :in_progress, priority: :high, position: 0,
    phase: "Components", start_date: today - 14, due_date: today + 7, percent_complete: 70 },
  { title: "Add DataTable filter persistence", description: "Save active filters to cookies for page reload", status: :in_progress, priority: :medium, position: 1,
    phase: "Components", start_date: today - 7, due_date: today + 10, percent_complete: 40 },
  { title: "Build Kanban component", description: "Drag-and-drop board composing SortableList", status: :in_progress, priority: :high, position: 2,
    phase: "Components", start_date: today - 10, due_date: today + 14, percent_complete: 55 },
  { title: "Create FeedbackWidget", description: "Floating button with iframe drawer for Opina", status: :todo, priority: :medium, position: 0,
    phase: "Components", start_date: today + 7, due_date: today + 21 },
  { title: "Add Carousel accessibility", description: "Keyboard navigation and ARIA labels for slides", status: :todo, priority: :high, position: 1,
    phase: "Quality", start_date: today + 14, due_date: today + 24 },
  { title: "Document FilterForm DSL", description: "Write guide for search_fields and filter_attribute", status: :todo, priority: :low, position: 2,
    phase: "Quality", start_date: today + 18, due_date: today + 28 },
  { title: "Explore Turbo Mount for charts", description: "Evaluate React-based charting via islands architecture", status: :backlog, priority: :low, position: 0 },
  { title: "Add dark mode support", description: "Verify all components render correctly with dark theme", status: :backlog, priority: :medium, position: 1,
    phase: "Quality", start_date: today + 25, due_date: today + 35 },
  { title: "Performance benchmark suite", description: "Measure render times for complex components", status: :backlog, priority: :low, position: 2,
    phase: "Quality" },
  { title: "Cut v3.1.0 beta", description: "Tag the release once the timeline components land", status: :todo, priority: :high, position: 3,
    phase: "Release", start_date: today + 42, due_date: today + 42, milestone: true }
]

tasks_data.each do |data|
  task = project.tasks.find_or_initialize_by(title: data[:title])
  task.assign_attributes(data.except(:title))
  task.save!
end

# Dependencies chain a critical path through the schedule so the Gantt island
# (#705) shows arrows and the critical treatment out of the box. The fake CPM
# (ProjectGantt#critical_ids) marks the longest total-duration chain.
dependency_pairs = [
  ["Audit existing icon usage", "Migrate to Lucide icons"],
  ["Migrate to Lucide icons", "Upgrade to daisyUI 5"],
  ["Upgrade to daisyUI 5", "Build Kanban component"],
  ["Add DataTable filter persistence", "Create FeedbackWidget"],
  ["Build Kanban component", "Cut v3.1.0 beta"]
]
dependency_pairs.each do |predecessor_title, successor_title|
  predecessor = project.tasks.find_by!(title: predecessor_title)
  successor = project.tasks.find_by!(title: successor_title)
  TaskDependency.find_or_create_by!(predecessor: predecessor, successor: successor)
end

puts "Created #{Project.count} projects with #{Task.count} tasks and #{TaskDependency.count} dependencies"

# #708 — un párrafo con referencias reales en el primer documento, para que /documents/:id
# tenga qué resolver al cargar (y qué materializar en bali_entity_references). Va aquí y no
# con el resto del contenido porque las entidades referidas se crean más arriba: una
# referencia solo demuestra algo si apunta a un registro que existe.
roadmap = Document.find_by(title: "Q2 2026 Product Roadmap")
if roadmap
  referenced_task = project.tasks.find_by(title: "Build Kanban component")
  archived = Document.find_by(title: "Archived: Legacy Migration Plan")

  references_paragraph = {
    "id" => "refs-1",
    "type" => "paragraph",
    "content" => [
      { "type" => "text", "text" => "Seguimiento en ", "styles" => {} },
      { "type" => "entityReference",
        "props" => { "entityType" => "Project", "entityId" => project.id.to_s,
                     "entityName" => project.name } },
      { "type" => "text", "text" => ", con ", "styles" => {} },
      { "type" => "entityReference",
        "props" => { "entityType" => "Task", "entityId" => referenced_task.id.to_s,
                     "entityName" => referenced_task.title } },
      { "type" => "text", "text" => " en curso. Reemplaza a ", "styles" => {} },
      # A un documento archivado: el chip se pinta roto, que es la señal que se perdería
      # si el resolver simplemente omitiera lo inalcanzable.
      { "type" => "entityReference",
        "props" => { "entityType" => "Document", "entityId" => archived.id.to_s,
                     "entityName" => archived.title } },
      { "type" => "text", "text" => ".", "styles" => {} }
    ]
  }

  unless roadmap.content.any? { |block| block["id"] == "refs-1" }
    roadmap.update!(content: roadmap.content + [ references_paragraph ])
  end

  puts "Document '#{roadmap.title}' references #{roadmap.entity_references.count} entities"
end

# Dueño de las vistas guardadas: el dummy no autentica, hay un solo usuario y es el que
# nombra el topbar.
User.demo
puts "Demo user: #{User::DEMO_NAME}"

puts "Seed data complete!"
