# frozen_string_literal: true
require 'minitest/autorun'
require 'tmpdir'
require 'query_ledger'

class StorageTest < Minitest::Test
  def test_unknown_collection_is_rejected
    assert_raises(QueryLedger::Error) { QueryLedger.read_json('unused.json', 'other') }
  end

  def test_invalid_fingerprint_never_enters_a_budget
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'budget.json')
      QueryLedger.atomic_write(file, { 'schema_version' => 1, 'budgets' => {
        'users' => { 'max' => 1, 'patterns' => { 'raw SQL is not a digest' => 1 } }
      } })
      assert_raises(QueryLedger::Error) { QueryLedger.read_json(file, 'budgets') }
    end
  end

  def test_nested_capture_keeps_independent_counts
    inner = nil
    outer = QueryLedger.capture do
      inner = QueryLedger.capture do
        ActiveSupport::Notifications.instrument('sql.active_record', sql: 'SELECT 1', name: 'Load') {}
      end
    end
    assert_equal 1, inner['count']
    assert_equal 1, outer['count']
  end
end
