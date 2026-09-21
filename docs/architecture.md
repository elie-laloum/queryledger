# Architecture

`lib/query_ledger.rb` is the public facade. Existing capture, compare, assertion and storage calls remain available.

| Module | Responsibility |
| --- | --- |
| `collector.rb` | Subscribe to SQL notifications in the calling thread/fiber; unsubscribe on exceptions. |
| `fingerprint.rb` | Normalize literals and export digests instead of SQL text. |
| `budget.rb` | Pure comparison and user-facing result messages. |
| `storage.rb` | Validate schema 1 and atomically write JSON. |
| `rspec.rb` | Optional block matcher integration. |
| `bin/queryledger` | Explicit record/compare commands and exit codes. |

Capture never installs a global lasting subscriber. Cached/schema/transaction/async events are excluded by policy. Baselines only change through explicit acceptance; missing budgets fail. The fingerprints are a heuristic for repeated statement shapes, not an SQL parser or a query-time measurement.

CI covers Ruby 3.4 and current Ruby 4.0. Rails dependencies are exercised with the current 8.1 branch. Tests include real Active Record/SQLite and CLI round trips.
