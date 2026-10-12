# frozen_string_literal: true

require "test_helper"
require "open3"

# The dummy's initializer configures these features at boot, so reading `Bali.*` here would see
# the dummy's values. A host that configures nothing gets what a fresh process loads.
class EngineFeatureDefaultsTest < ActiveSupport::TestCase
  PROBE = <<~RUBY
    require "rails/all"
    require "bali_view_components"
    print [
      Bali.archivables, Bali.archivals_authorize.call(nil, nil, :create),
      Bali.archivals_successors.call(nil, nil),
      Bali.content_versionables, Bali.content_versions_authorize.call(nil, nil, :show)
    ].inspect
  RUBY

  def test_an_unconfigured_host_resolves_no_record_and_authorizes_nothing
    output, status = Open3.capture2e(RbConfig.ruby, "-I", Bali::Engine.root.join("lib").to_s,
                                     "-e", PROBE)

    assert status.success?, output
    assert_equal "[{}, false, nil, {}, false]", output
  end
end
