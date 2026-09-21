# frozen_string_literal: true
require 'active_support'
require 'active_support/notifications'
require_relative 'fingerprint'

module QueryLedger
  module Collector
    def self.capture(include_cached: false)
      owner_thread, owner_fiber = Thread.current, Fiber.current
      patterns = Hash.new(0)
      callback = lambda do |_name, _start, _finish, _id, payload|
        next unless Thread.current == owner_thread && Fiber.current == owner_fiber
        next if payload[:async]
        next if %w[SCHEMA TRANSACTION].include?(payload[:name].to_s.upcase)
        next if payload[:cached] && !include_cached
        next if payload[:sql].to_s.match?(/\A\s*(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)\b/i)
        patterns[Fingerprint.call(payload[:sql])] += 1
      end
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { yield }
      { 'count' => patterns.values.sum, 'patterns' => patterns.sort.to_h }
    end
  end
end
