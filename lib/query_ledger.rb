require 'active_support'
require 'active_support/notifications'
require 'digest'
require 'json'
require 'fileutils'
require 'tempfile'
require_relative 'query_ledger/version'

module QueryLedger
  class Error < StandardError; end
  class BudgetExceeded < Error; end

  # Only digests leave the collector; raw SQL and bind values are never exported.
  def self.fingerprint(sql)
    normalized = sql.to_s.gsub(/\/\*.*?\*\//m, ' ').gsub(/--[^\n]*/, ' ')
                    .gsub(/'(?:''|\\.|[^'])*'/, '?')
                    .gsub(/\b(?:0x[0-9a-f]+|\d+(?:\.\d+)?(?:e[+-]?\d+)?)\b/i, '?')
                    .gsub(/\$\d+|:\w+/, '?').gsub(/\s+/, ' ').strip
    Digest::SHA256.hexdigest(normalized)
  end

  def self.capture(include_cached: false)
    owner_thread, owner_fiber = Thread.current, Fiber.current
    patterns = Hash.new(0)
    callback = lambda do |_name, _start, _finish, _id, payload|
      next unless Thread.current == owner_thread && Fiber.current == owner_fiber
      next if payload[:async]
      next if %w[SCHEMA TRANSACTION].include?(payload[:name].to_s.upcase)
      next if payload[:cached] && !include_cached
      next if payload[:sql].to_s.match?(/\A\s*(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)\b/i)
      patterns[fingerprint(payload[:sql])] += 1
    end
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { yield }
    { 'count' => patterns.values.sum, 'patterns' => patterns.sort.to_h }
  end

  def self.read_json(file, collection)
    obj = JSON.parse(File.read(file))
    raise Error, "Invalid schema in #{file}" unless obj.is_a?(Hash) && obj['schema_version'] == 1 && obj[collection].is_a?(Hash)
    obj[collection].each do |key, entry|
      field = collection == 'budgets' ? 'max' : 'count'
      unless key.is_a?(String) && entry.is_a?(Hash) && entry[field].is_a?(Integer) && entry[field] >= 0
        raise Error, "Invalid #{collection} entry: #{key}"
      end
      patterns = entry.fetch('patterns', {})
      unless patterns.is_a?(Hash) && patterns.all? { |hash, n| hash.match?(/\A[0-9a-f]{64}\z/) && n.is_a?(Integer) && n >= 0 }
        raise Error, "Invalid fingerprints for #{key}"
      end
    end
    obj
  rescue JSON::ParserError, Errno::ENOENT => e
    raise Error, e.message
  end

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

  def self.assert_budget(key, baseline:, include_cached: false)
    budget = read_json(baseline, 'budgets')['budgets'][key]
    raise Error, "No explicit budget for #{key}" unless budget
    sample = capture(include_cached: include_cached) { yield }
    result = compare(sample, budget, key: key)
    raise BudgetExceeded, message(result) unless result['passed']
    sample
  end

  def self.write_report(file, samples)
    atomic_write(file, { 'schema_version' => 1, 'samples' => samples })
  end

  def self.atomic_write(file, value)
    directory = File.dirname(File.expand_path(file))
    FileUtils.mkdir_p(directory)
    Tempfile.create(['queryledger-', '.json'], directory) do |f|
      f.write(JSON.pretty_generate(value) + "\n")
      f.flush
      f.fsync
      f.close
      File.rename(f.path, file)
    end
  end
end
