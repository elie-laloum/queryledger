# frozen_string_literal: true
require 'json'
require 'fileutils'
require 'tempfile'
require_relative 'errors'

module QueryLedger
  module Storage
    def self.read(file, collection)
      raise Error, 'Unknown report collection' unless %w[budgets samples].include?(collection)
      obj = JSON.parse(File.read(file))
      raise Error, "Invalid schema in #{file}" unless obj.is_a?(Hash) && obj['schema_version'] == 1 && obj[collection].is_a?(Hash)
      obj[collection].each do |key, entry|
        field = collection == 'budgets' ? 'max' : 'count'
        unless key.is_a?(String) && entry.is_a?(Hash) && entry[field].is_a?(Integer) && entry[field] >= 0
          raise Error, "Invalid #{collection} entry: #{key}"
        end
        patterns = entry.fetch('patterns', {})
        unless patterns.is_a?(Hash) && patterns.all? { |hash, n| hash.is_a?(String) && hash.match?(/\A[0-9a-f]{64}\z/) && n.is_a?(Integer) && n >= 0 }
          raise Error, "Invalid fingerprints for #{key}"
        end
      end
      obj
    rescue JSON::ParserError, Errno::ENOENT => e
      raise Error, e.message
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
end
