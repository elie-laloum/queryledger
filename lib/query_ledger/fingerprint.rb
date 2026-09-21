# frozen_string_literal: true
require 'digest'

module QueryLedger
  module Fingerprint
    def self.call(sql)
      normalized = sql.to_s.gsub(/\/\*.*?\*\//m, ' ').gsub(/--[^\n]*/, ' ')
                      .gsub(/'(?:''|\\.|[^'])*'/, '?')
                      .gsub(/\b(?:0x[0-9a-f]+|\d+(?:\.\d+)?(?:e[+-]?\d+)?)\b/i, '?')
                      .gsub(/\$\d+|:\w+/, '?').gsub(/\s+/, ' ').strip
      Digest::SHA256.hexdigest(normalized)
    end
  end
end
