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
  { name: 'The Dark Knight', genre: 'Action', status: :done, tenant: tenants[0], indie: false },
  { name: 'Inception', genre: 'Sci-Fi', status: :done, tenant: tenants[0], indie: false },
  { name: 'Interstellar', genre: 'Sci-Fi', status: :done, tenant: tenants[1], indie: false },
  { name: 'Jurassic Park', genre: 'Adventure', status: :done, tenant: tenants[1], indie: false },
  { name: 'The Godfather', genre: 'Drama', status: :done, tenant: tenants[2], indie: false },
  { name: 'Forrest Gump', genre: 'Drama', status: :done, tenant: tenants[2], indie: false },
  { name: 'Top Gun: Maverick', genre: 'Action', status: :done, tenant: tenants[2], indie: false },
  { name: 'The Avengers', genre: 'Action', status: :done, tenant: tenants[3], indie: false },
  { name: 'Frozen', genre: 'Animation', status: :done, tenant: tenants[3], indie: false },
  { name: 'The Lion King', genre: 'Animation', status: :done, tenant: tenants[3], indie: false },
  { name: 'Everything Everywhere All at Once', genre: 'Sci-Fi', status: :done, tenant: tenants[4], indie: true },
  { name: 'Moonlight', genre: 'Drama', status: :done, tenant: tenants[4], indie: true },
  { name: 'Lady Bird', genre: 'Comedy', status: :done, tenant: tenants[4], indie: true },
  { name: 'Hereditary', genre: 'Horror', status: :done, tenant: tenants[4], indie: true },
  { name: 'Midsommar', genre: 'Horror', status: :done, tenant: tenants[4], indie: true },
  { name: 'Untitled Project 1', genre: 'Drama', status: :draft, tenant: tenants[0], indie: false },
  { name: 'Untitled Project 2', genre: 'Action', status: :draft, tenant: tenants[1], indie: false },
  { name: 'Untitled Project 3', genre: 'Comedy', status: :draft, tenant: tenants[2], indie: true },
  { name: 'The Matrix Resurrections', genre: 'Sci-Fi', status: :done, tenant: tenants[0], indie: false },
  { name: 'Dune', genre: 'Sci-Fi', status: :done, tenant: tenants[0], indie: false }
]

movies_data.each_with_index do |data, index|
  movie = Movie.find_or_initialize_by(name: data[:name])
  # Spread movies across the last 2 years with varied dates
  days_ago = (index * 37) % 730 # Spread across ~2 years
  movie.update!(
    genre: data[:genre],
    status: data[:status],
    tenant: data[:tenant],
    indie: data[:indie],
    created_at: days_ago.days.ago
  )
end

puts "Created #{Movie.count} movies"
puts "Seed data complete!"
