require 'minitest/autorun'
require 'tmpdir'
require 'open3'
require 'query_ledger'

class QueryLedgerTest < Minitest::Test
  def sql(value = "SELECT * FROM users WHERE id=1", **payload)
    ActiveSupport::Notifications.instrument('sql.active_record', { sql: value, name: 'User Load' }.merge(payload)) {}
  end

  def test_normalizes_values_without_exporting_sql
    a = QueryLedger.capture { sql("SELECT * FROM users WHERE email='secret@example.com' AND id=17") }
    b = QueryLedger.capture { sql("SELECT * FROM users WHERE email='other@example.com' AND id=21") }
    assert_equal a, b
    refute_includes JSON.generate(a), 'secret'
    refute_includes JSON.generate(a), 'SELECT'
  end

  def test_filters_cached_schema_transactions_and_other_threads
    result = QueryLedger.capture do
      sql
      sql(cached: true)
      sql(name: 'SCHEMA')
      sql('BEGIN')
      sql(async: true)
      Thread.new { sql }.join
      Fiber.new { sql }.resume
    end
    assert_equal 1, result['count']
    assert_equal 1, QueryLedger.capture(include_cached: true) { sql(cached: true) }['count']
  end

  def test_exception_unsubscribes_and_does_not_swallow_application_failure
    assert_raises(ArgumentError) { QueryLedger.capture { raise ArgumentError, 'application failure' } }
    assert_equal 1, QueryLedger.capture { sql }['count']
  end

  def test_fails_for_budget_regression_and_missing_budget
    Dir.mktmpdir do |dir|
      baseline = File.join(dir, 'budget.json')
      QueryLedger.atomic_write(baseline, { 'schema_version' => 1, 'budgets' => { 'users' => { 'max' => 1 } } })
      assert_raises(QueryLedger::BudgetExceeded) { QueryLedger.assert_budget('users', baseline: baseline) { 2.times { sql } } }
      assert_raises(QueryLedger::Error) { QueryLedger.assert_budget('missing', baseline: baseline) { sql } }
    end
  end

  def test_cli_requires_accept_and_catches_missing_samples
    Dir.mktmpdir do |dir|
      baseline, report = File.join(dir, 'budget.json'), File.join(dir, 'report.json')
      QueryLedger.write_report(report, { 'users' => QueryLedger.capture { sql } })
      cli = File.expand_path('../bin/queryledger', __dir__)
      args = [RbConfig.ruby, cli, 'record', '--baseline', baseline, '--report', report]
      _, _, status = Open3.capture3(*args)
      assert_equal 2, status.exitstatus
      refute File.exist?(baseline)
      _, _, status = Open3.capture3(*args, '--accept')
      assert status.success?
      QueryLedger.write_report(report, { 'users' => QueryLedger.capture { 2.times { sql } } })
      _, _, status = Open3.capture3(RbConfig.ruby, cli, 'compare', '--baseline', baseline, '--report', report)
      assert_equal 1, status.exitstatus
      QueryLedger.write_report(report, { 'other' => { 'count' => 0, 'patterns' => {} } })
      _, _, status = Open3.capture3(RbConfig.ruby, cli, 'compare', '--baseline', baseline, '--report', report)
      assert_equal 2, status.exitstatus
    end
  end
end
