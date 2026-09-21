<p align="center"><strong>English</strong> · <a href="README.fr.md">Français</a></p>

<p align="center"><img src="assets/hero.svg" alt="QueryLedger — Give every Rails endpoint a query budget." width="100%"></p>

# QueryLedger

**Give every Rails endpoint a query budget.**

A proposed open-source Ruby gem for making SQL query regressions visible in Rails tests and code review.

> **In development.** This repository contains the initial specification and documentation. No executable release has shipped yet.


**Original repository: [GitLab](https://gitlab.elielaloum.com/elielaloum/queryledger)** · [Public GitHub mirror](https://github.com/elie-laloum/queryledger). The GitLab origin is private and requires access. Code changes are integrated in GitLab and synchronized to GitHub.


## Keep query costs in the review

A small application change can add database work to a frequently used endpoint. QueryLedger should compare test-time query counts with a versioned budget and show which query patterns changed.

```text
Run request spec → Capture queries → Compare budget → Explain regression
```

## First release scope

- Rails applications using RSpec request specs.
- Query collection through Active Support's `sql.active_record` event.
- Per-example budgets and an explicitly reviewed baseline.
- Normalized query fingerprints, count differences, and available call sites.
- A readable test failure plus a machine-readable report.

Start with synchronous tests. Document cache behavior and exclusions for schema and transaction queries. SQL duration should be informational initially, because environment noise makes strict timing budgets less reproducible.

## Where it fits

[Bullet](https://github.com/flyerhzm/bullet) already detects N+1 queries and can fail tests. QueryLedger's proposed focus is an explicit query budget and a reviewable baseline comparison. It should complement existing detection tools.

## The demo we will ship

A small Rails application, a passing query budget, a real regression, its test failure, and the verified correction. Every displayed count should come from the recorded run.

## Release requirements

No silent baseline updates. Exclude sensitive SQL values from exported reports. Test regression detection, query exclusions, and the supported Ruby/Rails matrix. Clearly document asynchronous work as outside the initial scope.

## Help shape it

Useful early contributions: minimal request-spec fixtures, adapter compatibility checks, and report feedback. Gem installation instructions will follow a verified package release.


---

[Roadmap](ROADMAP.md) · [Contributing](CONTRIBUTING.md) · [MIT license](LICENSE)
