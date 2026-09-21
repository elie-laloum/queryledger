<p align="right"><a href="README.fr.md">Français</a></p>
<img src="assets/cover-v2.png" alt="QueryLedger — Give your SQL queries a budget." width="100%">

[![CI](https://img.shields.io/github/actions/workflow/status/elie-laloum/queryledger/ci.yml?branch=main&style=flat-square&label=CI)](https://github.com/elie-laloum/queryledger/actions/workflows/ci.yml) [![License](https://img.shields.io/badge/license-MIT-586475?style=flat-square)](LICENSE)

**Turn query counts into explicit test expectations. Catch an N+1 before it becomes a production surprise.**

Ruby 3.4+ · Active Record · RSpec · [Quick start](#quick-start) · [How it works](#how-it-works) · [Boundaries](#boundaries)

## See it in action

<a href="assets/demo.mp4"><img src="assets/demo.gif" alt="QueryLedger — recorded demonstration" width="100%"></a>

<sub>Replay of a real demo run, with explanatory annotations and timing edited for readability.</sub>

[Watch the MP4](assets/demo.mp4) · [Reproduce this demo](docs/demo.md)

## Why it exists

### Budget the behavior
Capture sql.active_record events around a block and compare the count with a named, versioned budget.

### Find the regression
Reports show which normalized query fingerprints increased. Raw SQL and bind values are not exported.

### Make changes deliberate
Missing budgets fail. Recording a new baseline requires --accept. Use the Ruby API, RSpec matcher or comparison CLI.

## Quick start

```sh
git clone https://github.com/elie-laloum/queryledger.git
cd queryledger
bundle install
bundle exec rake test
bundle exec ruby examples/demo.rb
```

Clone and run from source; these commands do not assume a package has been published to a registry.

## How it works

`Capture → record → review → compare`

The SQLite example loads three authors and their posts. Lazy association loading produces four queries against a budget of two. Adding includes(:posts) brings the same operation back to two queries.

## Use it on your project

Add this checkout to your development/test Gemfile with `gem "queryledger", path: "/path/to/queryledger"`, then `bundle install`.

```ruby
require "query_ledger"

sample = QueryLedger.capture do
  Author.includes(:posts).each { |author| author.posts.to_a }
end
QueryLedger.write_report("query-report.json", { "authors/index" => sample })
```

Review the report, then accept the initial budget explicitly:

```sh
bundle exec ruby bin/queryledger record --baseline query-budgets.json --report query-report.json --accept
bundle exec ruby bin/queryledger compare --baseline query-budgets.json --report query-report.json
```

Or enforce the budget in RSpec:

```ruby
require "query_ledger/rspec"

expect { Author.includes(:posts).each { |a| a.posts.to_a } }
  .to stay_within_query_budget("authors/index", baseline: "query-budgets.json")
```

Commit the budget file. A regression exits with status 1; a missing budget or invalid report exits with status 2. The CLI expects a report covering every budgeted key.

## Boundaries

Counts synchronous queries on the capturing thread and fiber. Async queries, schema/transaction events and cached results are excluded by default. Set include_cached: true when needed. Fingerprints are a lightweight normalizer, not a SQL parser. Query count is not latency: use a profiler for expensive individual queries.

## Development

See the [module map](docs/architecture.md) and [contribution workflow](CONTRIBUTING.md).


Run `bundle exec rake test` and `bundle exec ruby examples/demo.rb`. The integration tests use real Active Record and SQLite.

[Contributing](CONTRIBUTING.md) · [Roadmap](ROADMAP.md) · [MIT license](LICENSE)

[GitLab origin](https://gitlab.elielaloum.com/elielaloum/queryledger) · [GitHub mirror](https://github.com/elie-laloum/queryledger)

The private GitLab repository is the source of record. This public mirror receives synchronized changes; GitLab access is required to view the origin.
