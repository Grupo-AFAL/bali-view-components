# frozen_string_literal: true

require "test_helper"

# #706 — the padlock on the wire format.
#
# `RESTThreadStore._normalizeThread` and `_normalizeComment`
# (app/components/bali/block_editor/RESTThreadStore.js) read a fixed set of snake_case
# keys off this JSON. They are not versioned and not negotiated: the day this gem
# publishes a renamed key, every host's editor stops rendering comments at once.
#
# So this test does not check "the JSON looks right". It asserts, key by key, that
# every name the JavaScript reaches for is present with the shape it expects, on a
# record where every optional field is populated. Changing a key here means changing
# the JS in the same commit — and every consuming app's data along with it.
class BaliBlockEditorJsonContractTest < ActiveSupport::TestCase
  # Exactly the keys `_normalizeThread` reads. `raw.deleted_at` is read too, but a
  # thread has no soft delete: the store treats a missing key as "not deleted".
  THREAD_KEYS = %w[id created_at updated_at comments resolved resolved_by
                   resolved_updated_at metadata].freeze

  # Exactly the keys `_normalizeComment` reads.
  COMMENT_KEYS = %w[id user_id created_at updated_at reactions metadata body deleted_at].freeze

  # `_normalizeComment` maps reactions to { emoji, createdAt, userIds }.
  REACTION_KEYS = %w[emoji created_at user_ids].freeze

  def setup
    @document = Document.create!(title: "Contrato", author_name: "Ana", content: [])
    @thread = Bali::BlockEditorThread.create!(commentable: @document, metadata: { "anchor" => "intro" })
    @comment = @thread.comments.create!(
      user_id: "user-1",
      body: [ { "type" => "paragraph", "content" => [ { "type" => "text", "text" => "Hola" } ] } ],
      metadata: { "mentions" => [ "user-2" ] }
    )
    @comment.reactions.create!(user_id: "user-1", emoji: "👍")
    @comment.reactions.create!(user_id: "user-2", emoji: "👍")
    @thread.resolve!("user-2")
  end

  # Round-tripping through JSON is the point: `as_json` returning a Time would pass a
  # naive key check and still hand the browser something `new Date()` cannot parse.
  def payload
    JSON.parse(@thread.reload.as_json.to_json)
  end

  def test_a_thread_carries_every_key_the_store_reads_and_no_stray_ones
    assert_equal THREAD_KEYS.sort, payload.keys.sort
  end

  def test_a_comment_carries_every_key_the_store_reads_and_no_stray_ones
    assert_equal COMMENT_KEYS.sort, payload["comments"].sole.keys.sort
  end

  def test_the_thread_values_are_the_types_the_store_can_consume
    thread = payload

    assert_equal @thread.id, thread["id"]
    assert_equal true, thread["resolved"]
    assert_equal "user-2", thread["resolved_by"]
    assert_equal({ "anchor" => "intro" }, thread["metadata"])
    # `new Date(...)` on anything else is an Invalid Date, and BlockNote renders NaN.
    [ "created_at", "updated_at", "resolved_updated_at" ].each do |key|
      assert_not_nil Time.iso8601(thread[key]), "#{key} is not parseable as ISO 8601"
    end
  end

  def test_the_comment_values_are_the_types_the_store_can_consume
    comment = payload["comments"].sole

    assert_equal @comment.id, comment["id"]
    assert_equal "user-1", comment["user_id"]
    assert_equal "Hola", comment.dig("body", 0, "content", 0, "text")
    assert_equal({ "mentions" => [ "user-2" ] }, comment["metadata"])
    assert_nil comment["deleted_at"]
  end

  # One row per user in the table, one entry per emoji on the wire — the grouping the
  # editor's reaction pills are built from.
  def test_reactions_arrive_grouped_by_emoji_with_the_user_ids_together
    reaction = payload["comments"].sole["reactions"].sole

    assert_equal REACTION_KEYS.sort, reaction.keys.sort
    assert_equal "👍", reaction["emoji"]
    assert_equal %w[user-1 user-2], reaction["user_ids"].sort
    assert_not_nil Time.iso8601(reaction["created_at"])
  end

  # A deleted comment stays in the list with a null body: the store reads `deleted_at`
  # to render the tombstone, and drops the body itself.
  def test_a_soft_deleted_comment_keeps_its_place_with_a_null_body
    @comment.soft_delete!
    comment = payload["comments"].sole

    assert_nil comment["body"]
    assert_not_nil Time.iso8601(comment["deleted_at"])
    assert_equal COMMENT_KEYS.sort, comment.keys.sort
  end

  # An unresolved thread with no metadata is the common case, and it must not answer
  # with missing keys — `metadata` in particular is spread into a JS object.
  def test_an_untouched_thread_still_answers_with_every_key
    bare = Bali::BlockEditorThread.create!(commentable: @document)
    bare.comments.create!(user_id: "user-1", body: [ { "type" => "paragraph" } ])
    payload = JSON.parse(bare.as_json.to_json)

    assert_equal THREAD_KEYS.sort, payload.keys.sort
    assert_equal({}, payload["metadata"])
    assert_equal false, payload["resolved"]
    assert_nil payload["resolved_by"]
    assert_nil payload["resolved_updated_at"]
    assert_equal [], payload["comments"].sole["reactions"]
  end
end
