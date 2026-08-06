# frozen_string_literal: true

require "test_helper"

# #706 — the nine endpoints of the RESTThreadStore contract, plus the two gates that
# stand in front of all of them. Identity and the commentable whitelist are injected
# through the same lambdas a host app configures, the way saved_views_test.rb does it.
#
# The permission matrix under test, which is BlockNote's `DefaultThreadStoreAuth`
# replayed server-side (the client-side one is decoration):
#
#   index, create, resolve/unresolve, add comment, react → anyone the authorize lambda admits
#   update / delete a comment                            → its author only
#   delete a thread                                      → the author of its FIRST comment
class BaliBlockEditorCommentsRequestTest < ActionDispatch::IntegrationTest
  AUTHOR = "user-1"
  STRANGER = "user-2"
  BODY = [ { "type" => "paragraph", "content" => [ { "type" => "text", "text" => "Hola" } ] } ].freeze

  def setup
    @document = Document.create!(title: "Contrato", author_name: "Ana", content: [])
    @originals = {
      commentables: Bali.block_editor_commentables,
      user: Bali.block_editor_comments_user,
      authorize: Bali.block_editor_comments_authorize
    }
    Bali.block_editor_commentables = { "Document" => Document }
    sign_in_as(AUTHOR)
  end

  def teardown
    Bali.block_editor_commentables = @originals[:commentables]
    Bali.block_editor_comments_user = @originals[:user]
    Bali.block_editor_comments_authorize = @originals[:authorize]
  end

  def sign_in_as(user_id)
    Bali.block_editor_comments_user = ->(_controller) { user_id }
  end

  # Every request carries the commentable, exactly as RESTThreadStore does: it is part
  # of the base URL's query string and `_buildUrl` keeps it on every sub-request.
  def scope(extra = {})
    { commentable_type: "Document", commentable_id: @document.id }.merge(extra)
  end

  def create_thread!(user_id: AUTHOR, body: BODY)
    Bali::BlockEditorThread.create!(commentable: @document).tap do |thread|
      thread.comments.create!(user_id: user_id, body: body)
    end
  end

  # --- GET / ---------------------------------------------------------------------

  def test_index_lists_only_the_threads_of_the_requested_commentable
    mine = create_thread!
    other_document = Document.create!(title: "Otro", author_name: "Ana", content: [])
    Bali::BlockEditorThread.create!(commentable: other_document)
                           .comments.create!(user_id: AUTHOR, body: BODY)

    get bali.block_editor_threads_path(scope)

    assert_response :success
    assert_equal [ mine.id ], response.parsed_body.map { |t| t["id"] }
  end

  def test_index_without_a_commentable_is_a_404_not_the_whole_table
    create_thread!

    get bali.block_editor_threads_path

    assert_response :not_found
  end

  # The nested endpoints already carry a thread id, so it would be tempting to let them
  # skip the scope. They must not: a thread id is guessable and the scope is the only
  # thing tying the request to a record the host said may be commented on.
  def test_no_endpoint_answers_without_the_commentable_not_even_the_ones_carrying_a_thread_id
    thread = create_thread!
    comment = thread.comments.first

    [
      -> { patch bali.block_editor_thread_path(thread), as: :json, params: { resolved: true } },
      -> { delete bali.block_editor_thread_path(thread) },
      -> { post bali.block_editor_thread_comments_path(thread), as: :json, params: { body: BODY } },
      -> { patch bali.block_editor_thread_comment_path(thread, comment), as: :json, params: { body: BODY } },
      -> { delete bali.block_editor_thread_comment_path(thread, comment) },
      -> { post bali.block_editor_thread_comment_reactions_path(thread, comment), as: :json, params: { emoji: "👍" } },
      -> { delete bali.block_editor_thread_comment_reactions_path(thread, comment), as: :json, params: { emoji: "👍" } }
    ].each_with_index do |request, index|
      request.call
      assert_response :not_found, "el endpoint #{index} respondió sin commentable"
    end

    assert_not thread.reload.resolved
    assert_nil comment.reload.deleted_at
  end

  def test_a_commentable_type_nobody_whitelisted_is_a_404
    get bali.block_editor_threads_path(commentable_type: "User", commentable_id: User.create!(name: "Ana").id)

    assert_response :not_found
  end

  def test_an_empty_whitelist_refuses_everything
    Bali.block_editor_commentables = {}

    get bali.block_editor_threads_path(scope)

    assert_response :not_found
  end

  # The String form is the one the guide recommends for an initializer: holding the class
  # object there pins the copy Zeitwerk discards on the next reload.
  def test_the_whitelist_takes_a_model_name_as_a_string
    Bali.block_editor_commentables = { "Document" => "Document" }
    create_thread!

    get bali.block_editor_threads_path(scope)

    assert_response :success
    assert_equal 1, response.parsed_body.length
  end

  # The lambda form is how a host narrows what is reachable — here, only published
  # documents, which is the shape an app with per-record access rules needs.
  def test_the_whitelist_takes_a_lambda_that_can_narrow_the_scope
    Bali.block_editor_commentables = { "Document" => ->(id) { Document.published.find_by(id: id) } }
    create_thread!

    get bali.block_editor_threads_path(scope)
    assert_response :not_found

    @document.published!
    get bali.block_editor_threads_path(scope)
    assert_response :success
  end

  def test_a_whitelisted_type_whose_record_is_gone_is_a_404
    get bali.block_editor_threads_path(commentable_type: "Document", commentable_id: @document.id + 999)

    assert_response :not_found
  end

  # --- the two gates -------------------------------------------------------------

  def test_without_a_resolved_user_every_endpoint_is_forbidden
    sign_in_as(nil)

    get bali.block_editor_threads_path(scope)
    assert_response :forbidden
  end

  def test_the_authorize_hook_sees_the_user_and_the_commentable
    seen = nil
    Bali.block_editor_comments_authorize = lambda do |_controller, user_id, commentable|
      seen = [ user_id, commentable ]
      false
    end

    get bali.block_editor_threads_path(scope)

    assert_response :forbidden
    assert_equal [ AUTHOR, @document ], seen
  end

  def test_the_x_user_id_header_never_decides_who_the_author_is
    post bali.block_editor_threads_path(scope), as: :json,
                                                headers: { "X-User-Id" => STRANGER },
                                                params: { initial_comment: { body: BODY } }

    assert_response :created
    assert_equal AUTHOR, Bali::BlockEditorComment.last.user_id
  end

  # --- POST / --------------------------------------------------------------------

  def test_create_opens_a_thread_on_the_commentable_with_its_first_comment
    assert_difference [ "Bali::BlockEditorThread.count", "Bali::BlockEditorComment.count" ], 1 do
      post bali.block_editor_threads_path(scope), as: :json, params: {
        initial_comment: { body: BODY, metadata: { "anchor" => "intro" } },
        metadata: { "source" => "toolbar" }
      }
    end

    assert_response :created
    thread = Bali::BlockEditorThread.last
    assert_equal @document, thread.commentable
    assert_equal({ "source" => "toolbar" }, thread.metadata)
    assert_equal AUTHOR, thread.comments.first.user_id
    assert_equal({ "anchor" => "intro" }, thread.comments.first.metadata)
  end

  # A BlockNote body is an array of block objects. Rails wraps each of those in its own
  # `ActionController::Parameters`, so what reaches the json column has to be converted
  # first — otherwise the column stores objects that only serialize correctly by
  # accident, and a reader gets something that is not a Hash.
  def test_the_stored_body_is_plain_json_all_the_way_down
    post bali.block_editor_threads_path(scope), as: :json,
                                                params: { initial_comment: { body: BODY } }

    body = Bali::BlockEditorComment.last.body
    assert_equal BODY, body
    assert_instance_of Hash, body.first
    assert_instance_of Hash, body.first["content"].first
  end

  def test_create_without_an_initial_comment_is_refused
    assert_no_difference "Bali::BlockEditorThread.count" do
      post bali.block_editor_threads_path(scope), as: :json, params: { metadata: {} }
    end

    assert_response :unprocessable_content
  end

  # --- PATCH /:id ----------------------------------------------------------------

  def test_anyone_with_access_resolves_and_unresolves_a_thread
    thread = create_thread!
    sign_in_as(STRANGER)

    patch bali.block_editor_thread_path(thread, scope), as: :json, params: { resolved: true }
    assert_response :success
    assert thread.reload.resolved
    assert_equal STRANGER, thread.resolved_by

    patch bali.block_editor_thread_path(thread, scope), as: :json, params: { resolved: false }
    assert_response :success
    assert_not thread.reload.resolved
    assert_nil thread.resolved_by
  end

  def test_a_thread_of_another_commentable_is_a_404
    other_document = Document.create!(title: "Otro", author_name: "Ana", content: [])
    foreign = Bali::BlockEditorThread.create!(commentable: other_document)

    patch bali.block_editor_thread_path(foreign, scope), as: :json, params: { resolved: true }

    assert_response :not_found
    assert_not foreign.reload.resolved
  end

  # --- DELETE /:id ---------------------------------------------------------------

  def test_only_the_author_of_the_first_comment_deletes_the_thread
    thread = create_thread!(user_id: AUTHOR)
    sign_in_as(STRANGER)

    assert_no_difference "Bali::BlockEditorThread.count" do
      delete bali.block_editor_thread_path(thread, scope)
    end
    assert_response :forbidden

    sign_in_as(AUTHOR)
    assert_difference "Bali::BlockEditorThread.count", -1 do
      delete bali.block_editor_thread_path(thread, scope)
    end
    assert_response :no_content
  end

  def test_deleting_a_thread_takes_its_comments_and_reactions_with_it
    thread = create_thread!
    thread.comments.first.reactions.create!(user_id: AUTHOR, emoji: "👍")

    assert_difference [ "Bali::BlockEditorComment.count", "Bali::BlockEditorReaction.count" ], -1 do
      delete bali.block_editor_thread_path(thread, scope)
    end
  end

  # --- POST /:thread/comments ----------------------------------------------------

  def test_anyone_with_access_adds_a_comment_to_an_existing_thread
    thread = create_thread!
    sign_in_as(STRANGER)

    assert_difference "Bali::BlockEditorComment.count", 1 do
      post bali.block_editor_thread_comments_path(thread, scope), as: :json, params: { body: BODY }
    end

    assert_response :created
    assert_equal STRANGER, thread.comments.last.user_id
  end

  # --- PATCH /:thread/comments/:id -----------------------------------------------

  def test_only_its_author_edits_a_comment
    thread = create_thread!(user_id: AUTHOR)
    comment = thread.comments.first
    edited = [ { "type" => "paragraph", "content" => [ { "type" => "text", "text" => "Editado" } ] } ]

    sign_in_as(STRANGER)
    patch bali.block_editor_thread_comment_path(thread, comment, scope), as: :json, params: { body: edited }
    assert_response :forbidden
    assert_equal BODY, comment.reload.body

    sign_in_as(AUTHOR)
    patch bali.block_editor_thread_comment_path(thread, comment, scope), as: :json, params: { body: edited }
    assert_response :success
    assert_equal edited, comment.reload.body
  end

  def test_editing_a_body_alone_leaves_the_metadata_alone
    thread = create_thread!
    comment = thread.comments.first
    comment.update!(metadata: { "anchor" => "intro" })

    patch bali.block_editor_thread_comment_path(thread, comment, scope), as: :json, params: { body: BODY }

    assert_response :success
    assert_equal({ "anchor" => "intro" }, comment.reload.metadata)
  end

  # --- DELETE /:thread/comments/:id ----------------------------------------------

  def test_only_its_author_deletes_a_comment_and_the_delete_is_soft
    thread = create_thread!(user_id: AUTHOR)
    thread.comments.create!(user_id: STRANGER, body: BODY)
    comment = thread.comments.first

    sign_in_as(STRANGER)
    delete bali.block_editor_thread_comment_path(thread, comment, scope)
    assert_response :forbidden

    sign_in_as(AUTHOR)
    assert_no_difference "Bali::BlockEditorComment.count" do
      delete bali.block_editor_thread_comment_path(thread, comment, scope)
    end
    assert_response :no_content

    comment.reload
    assert_nil comment.body
    assert_not_nil comment.deleted_at
  end

  def test_deleting_the_last_live_comment_takes_the_thread_with_it
    thread = create_thread!

    assert_difference "Bali::BlockEditorThread.count", -1 do
      delete bali.block_editor_thread_comment_path(thread, thread.comments.first, scope)
    end
    assert_response :no_content
  end

  # --- reactions ------------------------------------------------------------------

  def test_reactions_are_added_and_removed_for_the_resolved_user
    thread = create_thread!
    comment = thread.comments.first

    assert_difference "Bali::BlockEditorReaction.count", 1 do
      post bali.block_editor_thread_comment_reactions_path(thread, comment, scope),
           as: :json, params: { emoji: "👍" }
    end
    assert_response :created
    assert_equal AUTHOR, comment.reactions.sole.user_id

    assert_difference "Bali::BlockEditorReaction.count", -1 do
      delete bali.block_editor_thread_comment_reactions_path(thread, comment, scope),
             as: :json, params: { emoji: "👍" }
    end
    assert_response :no_content
  end

  def test_the_same_user_cannot_react_twice_with_the_same_emoji
    thread = create_thread!
    comment = thread.comments.first
    comment.reactions.create!(user_id: AUTHOR, emoji: "👍")

    assert_no_difference "Bali::BlockEditorReaction.count" do
      post bali.block_editor_thread_comment_reactions_path(thread, comment, scope),
           as: :json, params: { emoji: "👍" }
    end
    assert_response :unprocessable_content
  end

  def test_deleting_a_reaction_only_ever_reaches_your_own
    thread = create_thread!
    comment = thread.comments.first
    theirs = comment.reactions.create!(user_id: STRANGER, emoji: "👍")

    assert_no_difference "Bali::BlockEditorReaction.count" do
      delete bali.block_editor_thread_comment_reactions_path(thread, comment, scope),
             as: :json, params: { emoji: "👍" }
    end
    assert_response :not_found
    assert Bali::BlockEditorReaction.exists?(theirs.id)
  end

  # --- Security-review hardening: every guarantee below is pinned by a test -------

  def test_an_emoji_is_a_grapheme_not_a_payload
    thread = create_thread!
    comment = thread.comments.first

    assert_no_difference "Bali::BlockEditorReaction.count" do
      post bali.block_editor_thread_comment_reactions_path(thread, comment, scope),
           as: :json, params: { emoji: "x" * 33 }
    end
    assert_response :unprocessable_content
  end

  def test_a_user_cannot_pile_unlimited_distinct_emojis_on_one_comment
    thread = create_thread!
    comment = thread.comments.first
    max = Bali::BlockEditorThreads::Comments::ReactionsController::MAX_REACTIONS_PER_USER
    max.times { |i| comment.reactions.create!(user_id: AUTHOR, emoji: "e#{i}") }

    assert_no_difference "Bali::BlockEditorReaction.count" do
      post bali.block_editor_thread_comment_reactions_path(thread, comment, scope),
           as: :json, params: { emoji: "🎉" }
    end
    assert_response :too_many_requests
  end

  def test_an_oversized_comment_body_is_rejected
    thread = create_thread!
    huge = [ { "type" => "paragraph", "content" => [ { "type" => "text", "text" => "x" * (Bali::BlockEditorComment::MAX_BODY_BYTES + 1) } ] } ]

    assert_no_difference "Bali::BlockEditorComment.count" do
      post bali.block_editor_thread_comments_path(thread, scope), as: :json, params: { body: huge }
    end
    assert_response :unprocessable_content
  end

  def test_oversized_metadata_is_rejected_on_comment_and_thread
    thread = create_thread!
    pad = { "pad" => "x" * (Bali::BlockEditorComment::MAX_METADATA_BYTES + 1) }

    assert_no_difference "Bali::BlockEditorComment.count" do
      post bali.block_editor_thread_comments_path(thread, scope), as: :json, params: { body: BODY, metadata: pad }
    end
    assert_response :unprocessable_content

    assert_no_difference "Bali::BlockEditorThread.count" do
      post bali.block_editor_threads_path(scope),
           as: :json, params: { metadata: pad, initial_comment: { body: BODY } }
    end
    assert_response :unprocessable_content
  end

  def test_a_commentable_cannot_accumulate_unlimited_threads
    now = Time.current
    max = Bali::BlockEditorThreadsController::MAX_THREADS_PER_COMMENTABLE
    Bali::BlockEditorThread.insert_all!(
      Array.new(max) { { commentable_type: "Document", commentable_id: @document.id, created_at: now, updated_at: now } }
    )

    assert_no_difference "Bali::BlockEditorThread.count" do
      post bali.block_editor_threads_path(scope), as: :json, params: { initial_comment: { body: BODY } }
    end
    assert_response :unprocessable_content
  end

  def test_a_tombstone_is_final
    thread = create_thread!
    comment = thread.comments.first
    thread.comments.create!(user_id: STRANGER, body: BODY) # keeps the thread alive
    delete bali.block_editor_thread_comment_path(thread, comment, scope)
    assert_response :no_content

    patch bali.block_editor_thread_comment_path(thread, comment, scope), as: :json, params: { body: BODY }

    assert_response :gone
    assert_nil comment.reload.body
  end

  def test_a_deleted_comment_takes_no_reactions
    thread = create_thread!
    comment = thread.comments.first
    thread.comments.create!(user_id: STRANGER, body: BODY)
    comment.soft_delete!

    assert_no_difference "Bali::BlockEditorReaction.count" do
      post bali.block_editor_thread_comment_reactions_path(thread, comment, scope),
           as: :json, params: { emoji: "👍" }
    end
    assert_response :not_found
  end

  def test_commentable_id_must_be_a_scalar
    create_thread!

    get bali.block_editor_threads_path(commentable_type: "Document", commentable_id: [ @document.id ])

    assert_response :not_found
  end

  def test_an_orphan_thread_is_not_deletable_by_an_anonymous_caller
    # The shape a `rename_table` migration of a pre-existing host table can leave
    # behind: a thread with no comments, in a host whose identity lambda returns nil.
    orphan = Bali::BlockEditorThread.create!(commentable: @document)
    Bali.block_editor_comments_authorize = ->(_controller, _user_id, _commentable) { true }
    sign_in_as(nil)

    assert_no_difference "Bali::BlockEditorThread.count" do
      delete bali.block_editor_thread_path(orphan, scope)
    end
    assert_response :forbidden
  end

  def test_an_arity_two_resolver_receives_the_controller_first
    seen = nil
    Bali.block_editor_commentables = {
      "Document" => lambda { |controller, id|
        seen = controller
        Document.find_by(id: id)
      }
    }
    create_thread!

    get bali.block_editor_threads_path(scope)

    assert_response :success
    assert_kind_of ActionController::Base, seen
  end

  def test_an_arity_one_resolver_still_works
    Bali.block_editor_commentables = { "Document" => ->(id) { Document.find_by(id: id) } }
    create_thread!

    get bali.block_editor_threads_path(scope)

    assert_response :success
  end
end
