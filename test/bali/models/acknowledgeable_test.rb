# frozen_string_literal: true

require "test_helper"

# #709 — the signature book the engine lends a host's model. `Document` (from the dummy) includes
# the concern, so this exercises exactly the adoption a real app is asked for.
class BaliAcknowledgeableTest < ActiveSupport::TestCase
  def setup
    @document = Document.create!(title: "Política de viáticos", author_name: "Ana")
    @ana = User.create!(name: "Ana")
    @beto = User.create!(name: "Beto")
  end

  def test_acknowledge_records_who_signed_what_and_when
    freeze_time do
      ack = @document.acknowledge(user: @ana)

      assert_equal @ana, ack.user
      assert_equal @document, ack.acknowledgeable
      assert_equal Time.current, ack.acknowledged_at
      assert_equal "1.0", ack.version_label
      assert_predicate @document.reload.acknowledgments, :one?
    end
  end

  def test_acknowledged_by_only_answers_for_whoever_signed
    @document.acknowledge(user: @ana)

    assert @document.acknowledged_by?(@ana)
    refute @document.acknowledged_by?(@beto)
  end

  # What makes this usable as evidence: acknowledging the same text again does not rewrite the date
  # the person signed it on.
  def test_acknowledging_the_same_version_twice_keeps_the_original_record_untouched
    first = travel_to(3.days.ago) { @document.acknowledge(user: @ana) }
    original_time = first.reload.acknowledged_at

    second = @document.acknowledge(user: @ana)

    assert_equal first.id, second.id
    assert_equal original_time.to_i, second.reload.acknowledged_at.to_i
    assert_equal 1, @document.acknowledgments.count
  end

  # Signing another version is a NEW act, so the date moves with the label. It is the deliberate
  # split from gobierno-corporativo, which keeps the old date and ends up claiming somebody signed
  # 2.0 before 2.0 existed.
  def test_re_acknowledging_a_new_version_label_updates_both_the_label_and_the_date
    first = travel_to(3.days.ago) { @document.acknowledge(user: @ana) }
    original_time = first.reload.acknowledged_at

    @document.version_label = "2.0"
    second = @document.acknowledge(user: @ana)

    assert_equal first.id, second.id, "sigue siendo la misma firma, no una segunda fila"
    assert_equal "2.0", second.reload.version_label
    assert_operator second.acknowledged_at, :>, original_time
    assert_equal 1, @document.acknowledgments.count
  end

  # The concern asks the model for `version_label` with `try`, so a model that does not even define
  # the method signs all the same — and one that defines it empty does too.
  def test_a_record_without_a_version_label_still_signs
    @document.version_label = nil

    ack = @document.acknowledge(user: @ana)

    assert_nil ack.version_label
    assert @document.acknowledged_by?(@ana)
  end

  def test_each_person_signs_once_per_record
    @document.acknowledge(user: @ana)
    @document.acknowledge(user: @beto)

    assert_equal 2, @document.acknowledgments.count

    assert_raises ActiveRecord::RecordInvalid do
      Bali::Acknowledgment.create!(acknowledgeable: @document, user: @ana,
                                   acknowledged_at: Time.current)
    end
  end

  def test_the_same_person_signs_each_record_separately
    other_document = Document.create!(title: "Otra", author_name: "Ana")

    @document.acknowledge(user: @ana)
    other_document.acknowledge(user: @ana)

    assert_equal 1, @document.acknowledgments.count
    assert_equal 1, other_document.acknowledgments.count
  end

  # A signature is unique by (what was signed, who signed) and BOTH halves are polymorphic: without
  # the `_type` in the index, a `Member` and a `User` with the same id would be the same signer — and
  # that clash cannot be reproduced with two independent id sequences, so what is pinned here is the
  # index definition.
  def test_the_uniqueness_index_scopes_on_both_polymorphic_types
    index = ActiveRecord::Base.connection.indexes("bali_acknowledgments")
                              .find { |i| i.name == "index_bali_acknowledgments_uniqueness" }

    assert index, "falta el índice de unicidad"
    assert index.unique
    assert_equal %w[acknowledgeable_type acknowledgeable_id user_type user_id], index.columns
  end

  def test_destroying_the_record_destroys_its_signatures
    @document.acknowledge(user: @ana)

    assert_difference "Bali::Acknowledgment.count", -1 do
      @document.destroy!
    end
  end

  # The column exists without a foreign key so that installing the signature book does not force
  # installing the content history (#707). Without it, it stays nil.
  def test_content_version_id_stays_empty_without_the_content_history
    ack = @document.acknowledge(user: @ana)

    assert_nil ack.content_version_id
  end

  def test_content_version_id_can_be_named_by_the_caller
    ack = @document.acknowledge(user: @ana, content_version_id: 42)

    assert_equal 42, ack.reload.content_version_id
  end
end
