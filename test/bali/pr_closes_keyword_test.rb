# frozen_string_literal: true

require "test_helper"
require "open3"
require "tempfile"

# The guard that stops a PR from trying to close an issue IN SPANISH.
#
# GitHub only closes the issue on merge with its own keywords, and every one of them is
# English. «Cierra #123» reads just as well, closes nothing, and the issue stays open with
# nobody the wiser. It happened dozens of times, so it stopped being a written rule and
# became a gate.
#
# And the gate is tested too: a hook that stops firing does not fail — it lets things
# through, which is exactly what it looks like when it works.
#
# `Rails.root` here is `test/dummy`, not the repo: the hook's path hangs off
# `Bali::Engine.root`, the gem's root — the same idiom `i18n_usage_test` and
# `stimulus_target_guards_test` use.
#
# Editing this file from a shell command trips the hook itself: it reads the command text, and
# a Spanish closing verb next to `gh pr create|edit` or `gh api … pulls` is what it blocks. Its
# matcher is `Bash` only, so edit here with an editor, not a heredoc.
class PrClosesKeywordTest < ActiveSupport::TestCase
  HOOK = Bali::Engine.root.join(".claude/hooks/pr-closes-keyword.sh").freeze

  test "the hook exists and is executable" do
    assert File.exist?(HOOK), "the hook is gone"
    assert File.executable?(HOOK), "the hook has to run without `bash` in front of it"
  end

  test "it is wired as a Bash PreToolUse in .claude/settings.json" do
    settings = JSON.parse(Bali::Engine.root.join(".claude/settings.json").read)
    pre = settings.dig("hooks", "PreToolUse")

    refute_nil pre, "without the PreToolUse entry the hook never runs"
    commands = pre.select { |e| e["matcher"] == "Bash" }.flat_map { |e| e["hooks"] }.map { |h| h["command"] }
    assert commands.any? { |c| c.include?("pr-closes-keyword.sh") },
           "the hook has to sit under the Bash matcher: #{commands.inspect}"
  end

  # --- what it blocks ---------------------------------------------------------

  test "it blocks a body file that says Cierra" do
    with_body("Cierra #963.\n\nTexto del PR.\n") do |path|
      status, error = run_hook("gh pr create --repo x/y --body-file #{path}")

      assert_equal 2, status, "2 is the only thing Claude reads as «do not do it»"
      assert_match(/Closes/, error, "the message has to say what to replace it with")
    end
  end

  test "it blocks on pr edit too, which is where a body gets corrected" do
    with_body("Cierra #12\n") do |path|
      status, = run_hook("gh pr edit 974 --repo x/y --body-file #{path}")
      assert_equal 2, status
    end
  end

  test "it blocks a body passed inline with --body" do
    status, = run_hook('gh pr create --body "Cierra #12 y algo más"')
    assert_equal 2, status
  end

  test "it blocks the other verbs that write themselves when drafting in Spanish" do
    %w[Resuelve Corrige Arregla].each do |verb|
      with_body("#{verb} #34\n") do |path|
        status, = run_hook("gh pr create --body-file #{path}")
        assert_equal 2, status, "«#{verb} #34» does not close anything on GitHub either"
      end
    end
  end

  # The REST route the team takes when GraphQL is rate-limited (POST and PATCH on `pulls`).
  test "it blocks a PR body sent through gh api, in every way the body travels" do
    with_body("Cierra #12\n") do |path|
      [
        "gh api repos/x/y/pulls -f title=t -f head=b -f base=main -F body=@#{path}",
        "gh api -X PATCH repos/x/y/pulls/12 --field 'body=@#{path}'",
        "gh api -X PATCH repos/x/y/pulls/12 -f body=\"$(cat #{path})\"",
        "gh api -X PATCH \\\n  repos/x/y/pulls/12 \\\n  -F body=@#{path}",
        "gh pr create -F #{path}"
      ].each do |cmd|
        status, = run_hook(cmd)
        assert_equal 2, status, cmd
      end
    end

    status, = run_hook("gh api -X PATCH repos/x/y/pulls/12 -f body='Cierra #12'")
    assert_equal 2, status, "an inline body"
  end

  # --- what it must NOT block -------------------------------------------------

  # Reading a PR, and the endpoints under `pulls/N/` — reviews, comments, a merge — carry no
  # PR body, so a review that quotes «Cierra #12» is not stopped.
  test "it lets reads, reviews and merges through gh api" do
    with_body("Esto no cierra nada. Cierra #12 era el problema.\n") do |path|
      [
        "gh api repos/x/y/pulls/12",
        "gh api repos/x/y/pulls/12 --jq .body",
        "gh api repos/x/y/pulls/12/reviews -F body=@#{path}",
        "gh api -X PUT repos/x/y/pulls/12/merge -f merge_method=merge"
      ].each do |cmd|
        status, = run_hook(cmd)
        assert_equal 0, status, cmd
      end
    end
  end

  test "it lets the correct body through, with the rest in Spanish" do
    with_body("Closes #963\n\nEl cuerpo sigue en español, que es lo normal aquí.\n") do |path|
      status, = run_hook("gh pr create --repo x/y --body-file #{path}")
      assert_equal 0, status
    end
  end

  test "it does not meddle with other commands" do
    [ "gh pr list --repo x/y", "echo Cierra #12", "git commit -m 'Cierra #12'" ].each do |cmd|
      status, = run_hook(cmd)
      assert_equal 0, status, "#{cmd} publishes no PR body"
    end
  end

  test "input it cannot parse is let through, not jammed" do
    # A broken gate cannot turn into a plug for everything else.
    status, = run_hook(nil, input: "esto no es json")
    assert_equal 0, status
  end

  private

  def with_body(text)
    file = Tempfile.new([ "body", ".md" ])
    file.write(text)
    file.flush
    yield file.path
  ensure
    file&.close!
  end

  def run_hook(command, input: nil)
    input ||= { tool_input: { command: command } }.to_json
    output, error, status = Open3.capture3("bash", HOOK.to_s, stdin_data: input)
    [ status.exitstatus, error, output ]
  end
end
