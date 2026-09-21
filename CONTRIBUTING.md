# Contributing

Use Ruby 4.0 (see .ruby-version). CI also covers Ruby 3.4. Run:

```sh
bundle install
bundle exec rake test
bundle exec ruby examples/demo.rb
gem build queryledger.gemspec
```

Read [architecture](docs/architecture.md). Keep collection separate from persistence and budget comparison. Preserve the public facade and JSON schema. Tests exercise real Active Record and SQLite; no application or database service is required.

For collector changes, test exceptions, nested subscribers and thread/fiber isolation. For storage changes, test invalid schema and baseline acceptance. Never put raw SQL or bind values in reports. Query count and query latency are distinct concerns.

GitHub issues and pull requests are welcome. Accepted changes are integrated into the private GitLab origin and mirrored back to GitHub.
