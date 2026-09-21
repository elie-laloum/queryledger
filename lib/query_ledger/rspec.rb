require 'rspec/expectations'
require_relative '../query_ledger'

RSpec::Matchers.define :stay_within_query_budget do |key, baseline:, include_cached: false|
  supports_block_expectations
  match do |operation|
    budget = QueryLedger.read_json(baseline, 'budgets')['budgets'][key]
    raise QueryLedger::Error, "No explicit budget for #{key}" unless budget
    sample = QueryLedger.capture(include_cached: include_cached, &operation)
    @query_ledger_result = QueryLedger.compare(sample, budget, key: key)
    @query_ledger_result['passed']
  end
  failure_message { QueryLedger.message(@query_ledger_result) }
  match_when_negated { |_operation| raise QueryLedger::Error, 'Negated query budgets are not supported' }
end
