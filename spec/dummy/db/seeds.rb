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
puts "Seed data complete!"
