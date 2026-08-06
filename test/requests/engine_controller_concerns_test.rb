# frozen_string_literal: true

require "test_helper"

# #710 — Bali.engine_controller_concerns: el punto de extensión para que el host inyecte
# concerns a los controllers del engine. Por isolate_namespace, Bali::ApplicationController
# NO hereda del ApplicationController del host, así que `current_user` no existe ahí solo;
# el engine incluye cada módulo del array en un to_prepare. Aquí el prepare! se dispara a
# mano, igual que lo dispara un reload en development o el boot en producción.
class BaliEngineControllerConcernsTest < ActionDispatch::IntegrationTest
  # Concern realista: enseña `current_user`, que es justo lo que el default de
  # `Bali.saved_views_owner` intenta leer. Módulo plano a propósito (sin
  # ActiveSupport::Concern): un módulo plano re-dispararía su hook `included` en cada
  # to_prepare si el engine no guardara la inclusión — el contador lo delata.
  module HostSession
    class << self
      attr_accessor :user, :included_count
    end
    self.included_count = 0

    def self.included(_base)
      self.included_count += 1
    end

    def current_user
      HostSession.user
    end
  end

  STORAGE = "movies_index"

  def setup
    @orig_concerns = Bali.engine_controller_concerns
    @orig_owner = Bali.saved_views_owner
    # El default real del engine — el que devuelve nil cuando nadie enseñó current_user.
    Bali.saved_views_owner = ->(controller) { controller.try(:current_user) }
    HostSession.user = User.create!(name: "Ana")
  end

  def teardown
    Bali.engine_controller_concerns = @orig_concerns
    Bali.saved_views_owner = @orig_owner
    # Ruby no des-incluye módulos: HostSession queda en los ancestors del controller para
    # el resto de la suite. Con `user` en nil, `current_user` vuelve a devolver nil y el
    # comportamiento observable de los demás tests no cambia.
    HostSession.user = nil
  end

  def test_an_injected_concern_teaches_current_user_to_the_engine_controllers
    Bali.engine_controller_concerns = [ HostSession ]
    Rails.application.reloader.prepare!

    assert_operator Bali::ApplicationController, :<, HostSession

    assert_difference "Bali::SavedView.count", 1 do
      post bali.saved_views_path(storage_id: STORAGE), params: {
        name: "Mías", payload: { "attributes" => {} }.to_json
      }
    end
    assert_response :redirect
    assert_equal HostSession.user, Bali::SavedView.last.owner
  end

  def test_assignment_alone_does_not_include_until_to_prepare_runs
    probe = Module.new
    Bali.engine_controller_concerns = [ probe ]

    refute_operator Bali::ApplicationController, :<, probe

    Rails.application.reloader.prepare!

    assert_operator Bali::ApplicationController, :<, probe
  end

  def test_the_include_is_idempotent_across_repeated_to_prepare_runs
    counter = Module.new do
      @included_count = 0

      def self.included(_base)
        @included_count += 1
      end

      def self.included_count
        @included_count
      end
    end
    Bali.engine_controller_concerns = [ counter ]

    2.times { Rails.application.reloader.prepare! }

    assert_equal 1, counter.included_count
  end
end
