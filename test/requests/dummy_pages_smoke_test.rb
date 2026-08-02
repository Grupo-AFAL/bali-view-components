# frozen_string_literal: true

require "test_helper"

# The dummy's own pages are the reference every host copies from, and nothing was asking
# them to render. `/sidemenu-example` carried an extra `<% end %>` for weeks (#789): the
# template did not compile, the route answered 500, and the full suite stayed green —
# component tests render classes rather than pages, the Lookbook sweep only walks
# `/lookbook/...`, and this page is not a preview. `/admin/analytics` (#781) had the same
# blind spot from the other side.
#
# So this walks every GET route the dummy declares itself and asserts it answers. It is a
# smoke test on purpose: it pins that the page renders at all, not what it renders. A page
# that renders *less* than it should still answers 200 — that shape of bug is what
# `test/dummy_component_keywords_test.rb` is for.
#
# The walk also reads the deprecator, and that is the second thing it pins (#797). The pages
# a host copies from cannot teach the call the library just deprecated, and 27 warnings per
# run is how a deprecator stops being read at all — the one that finally matters scrolls past
# with the rest.
class DummyPagesSmokeTest < ActionDispatch::IntegrationTest
  # Controllers the dummy does not own. Rails, Turbo, Active Storage and ViewComponent ship
  # these; whether they answer is their maintainers' problem, not this app's.
  FOREIGN_CONTROLLERS = %r{\A(rails/|active_storage/|action_mailbox/|turbo/|view_components)}

  # Routes owned by the dummy that the sweep deliberately does not request, each with the
  # reason. The guard below fails on anything owned by the dummy that is neither swept nor
  # listed here, so a new page cannot join the app without someone deciding about it.
  UNSWEPT = {
    "documents/comment_threads#index" => "Turbo Stream partial; a bare GET has no frame to " \
                                         "render into and the JSON shape belongs to a " \
                                         "controller test"
  }.freeze

  # Deprecations the dummy fires on purpose, keyed by the leading text of the entry the
  # walk builds — `<path> (<endpoint>): <message>` — so an exception covers the call site
  # it was written for and not the component everywhere. A fifth page reaching for Level
  # still fails.
  #
  # Zero is the goal and the rest of this list is meant to be deleted, not extended: the
  # guard below fails on an entry that no longer fires, so whoever removes the call site
  # is told to remove its exception too.
  #
  def setup
    @tenant = Tenant.create!(name: "Smoke Studio")
    @movie = @tenant.movies.create!(name: "Smoke Movie", status: 0, genre: "Drama", rating: 8)
    @studio = Studio.create!(name: "Smoke Studio", country: "USA", status: :active)
    @project = Project.create!(name: "Smoke Project")
    @document = Document.create!(title: "Smoke Document", author_name: "Smoke Author")
    @version = @document.create_version!(author_name: "Smoke Author")
  end

  # Two assertions off one walk rather than two test methods, because the walk is the
  # expensive part: rendering all 51 pages a second time to read a different side effect
  # would cost more than the check is worth.
  #
  # Rendering is asserted first on purpose. A page that 500s never reaches the call site
  # that would have warned, so its silence about deprecations would mean nothing.
  def test_every_page_the_dummy_serves_answers_without_deprecation_warnings
    failures, deprecations = walk

    assert_empty failures, "dummy pages that do not render:\n#{failures.join("\n")}"

    assert_empty deprecations,
      "dummy pages calling a deprecated API. Migrate the call site:\n" \
      "#{deprecations.join("\n")}"
  end

  # Without this the list above rots: a page added to the dummy would simply never be
  # requested, which is the state that let #789 and #781 happen.
  def test_no_page_escapes_the_sweep
    covered = (swept_routes.map { |route| endpoint(route) } + UNSWEPT.keys).uniq
    missed = dummy_routes.map { |route| endpoint(route) }.uniq - covered

    assert_empty missed,
      "GET routes the dummy owns that nothing requests. Give each one its segments in " \
      "`segment_values`, or add it to UNSWEPT with the reason:\n#{missed.join("\n")}"
  end

  private

  # Requests every swept route once, returning the pages that did not render and the
  # deprecations they emitted while rendering. Both come off the same pass so the sweep
  # stays one walk.
  def walk
    failures = []
    deprecations = []

    warn_into(deprecations) do
      swept_routes.each do |route|
        path = expand(route)
        @current_page = "#{path} (#{endpoint(route)})"
        # Rescued rather than left to propagate so the sweep reports every broken page in
        # one run: a template that raises is exactly the case this exists for, and letting
        # the first one abort the loop would hide the rest.
        begin
          get path
          next if response.successful?

          failures << "#{@current_page} -> #{response.status} #{first_error_line}"
        rescue StandardError => e
          failures << "#{@current_page} -> raised #{e.class}: #{e.message.lines.first.to_s.strip}"
        end
      end
    end

    [ failures, deprecations ]
  end

  # Bali's deprecator is process-wide, so the previous behavior is restored rather than
  # reset to a literal: the test env configures it and this must not quietly redefine it
  # for whatever runs next.
  def warn_into(collected)
    original = Bali.deprecator.behavior
    Bali.deprecator.behavior = ->(message, *) do
      # The page is what makes a warning actionable. The message's own `called from` names
      # the component that raised it, which is one shared line for every call site.
      collected << "#{@current_page}: #{summarize(message)}"
    end
    yield
  ensure
    Bali.deprecator.behavior = original
  end

  # Drops the `DEPRECATION WARNING:` prefix and the `(called from ...)` suffix ActiveSupport
  # wraps around the text, which are noise once the page is named.
  def summarize(message)
    message.sub(/\ADEPRECATION WARNING: /, "").sub(/ \(called from .*\z/m, "").strip
  end

  # The record each dynamic segment resolves to, keyed by the controller that owns the route
  # and then by the segment's name. A segment with no entry drops its route out of the sweep
  # and into the guard above, so a new nested resource forces a decision rather than passing
  # silently.
  def segment_values
    {
      "movies" => { "id" => @movie.to_param },
      "admin/movies" => { "id" => @movie.to_param },
      "characters" => { "movie_id" => @movie.to_param },
      "admin/characters" => { "movie_id" => @movie.to_param },
      "studios" => { "id" => @studio.to_param },
      "admin/studios" => { "id" => @studio.to_param },
      "admin/projects" => { "id" => @project.to_param },
      "documents" => { "id" => @document.to_param },
      "document_versions" => { "document_id" => @document.to_param, "id" => @version.to_param }
    }
  end

  def dummy_routes
    Rails.application.routes.routes.select do |route|
      route.app.dispatcher? &&
        route.verb.include?("GET") &&
        route.defaults[:controller].present? &&
        !route.defaults[:controller].match?(FOREIGN_CONTROLLERS)
    end
  end

  def swept_routes
    dummy_routes.reject { |route| UNSWEPT.key?(endpoint(route)) }
      .select { |route| segments(route).all? { |name| resolvable?(route, name) } }
  end

  def endpoint(route)
    "#{route.defaults[:controller]}##{route.defaults[:action]}"
  end

  def segments(route)
    route.path.required_names
  end

  def resolvable?(route, name)
    segment_values.dig(route.defaults[:controller], name).present?
  end

  def expand(route)
    route.path.spec.to_s.sub(/\(\.:format\)\z/, "").gsub(/:(\w+)/) do
      segment_values.fetch(route.defaults[:controller]).fetch(Regexp.last_match(1))
    end
  end

  def first_error_line
    return "" unless response.body.present?

    response.body[/<h1>(.*?)<\/h1>/m, 1].to_s.strip.first(300)
  end
end
