# frozen_string_literal: true
require_relative 'query_ledger/version'
require_relative 'query_ledger/errors'
require_relative 'query_ledger/fingerprint'
require_relative 'query_ledger/collector'
require_relative 'query_ledger/storage'
require_relative 'query_ledger/budget'

# Public facade. Capture, persistence and comparison can be exercised independently.
module QueryLedger
  def self.fingerprint(sql) = Fingerprint.call(sql)
  def self.capture(include_cached: false, &block) = Collector.capture(include_cached: include_cached, &block)
  def self.read_json(file, collection) = Storage.read(file, collection)
  def self.compare(sample, budget, key: 'query budget') = Budget.compare(sample, budget, key: key)
  def self.message(result) = Budget.message(result)
  def self.atomic_write(file, value) = Storage.atomic_write(file, value)

  def self.write_report(file, samples)
    atomic_write(file, { 'schema_version' => 1, 'samples' => samples })
  end

  def self.assert_budget(key, baseline:, include_cached: false)
    budget = read_json(baseline, 'budgets')['budgets'][key]
    raise Error, "No explicit budget for #{key}" unless budget
    sample = capture(include_cached: include_cached) { yield }
    result = compare(sample, budget, key: key)
    raise BudgetExceeded, message(result) unless result['passed']
    sample
  end
end
