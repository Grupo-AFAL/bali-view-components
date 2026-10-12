# frozen_string_literal: true

# The dummy's Movie declares itself reversible with `successor_required_for: %i[replaced]`. A test
# that needs another declaration takes it for its block; the dummy's comes back afterwards.
module ArchivableDeclaration
  ATTRIBUTES = %i[archival_reasons archival_successor_required_for archival_reversible].freeze

  def with_archivable(**declaration)
    saved = ATTRIBUTES.to_h { |name| [ name, Movie.public_send(name) ] }
    Movie.archivable(**declaration)
    yield
  ensure
    saved.each { |name, value| Movie.public_send(:"#{name}=", value) }
  end
end
