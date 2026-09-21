# frozen_string_literal: true
require_relative 'errors'

module QueryLedger
  module Budget
    def self.compare(sample, budget, key: 'query budget')
      raise Error, "No explicit budget for #{key}" unless budget && budget['max'].is_a?(Integer) && budget['max'] >= 0
      old = budget.fetch('patterns', {})
      changes = sample.fetch('patterns', {}).filter_map do |id, count|
        delta = count - old.fetch(id, 0)
        { 'fingerprint' => id, 'added' => delta } if delta.positive?
      end
      { 'key' => key, 'count' => sample.fetch('count'), 'max' => budget['max'],
        'passed' => sample.fetch('count') <= budget['max'], 'increased_patterns' => changes }
    end

    def self.message(result)
      "#{result['key']}: #{result['count']} SQL queries; budget #{result['max']} (#{result['passed'] ? 'PASS' : 'FAIL'}). " \
        "#{result['increased_patterns'].length} query patterns increased."
    end
  end
end
