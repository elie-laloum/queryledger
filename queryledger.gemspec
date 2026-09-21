require_relative 'lib/query_ledger/version'
Gem::Specification.new do |s|
  s.name = 'queryledger'
  s.version = QueryLedger::VERSION
  s.summary = 'Versioned query budgets for Rails request specs'
  s.description = 'Capture SQL activity, compare query counts to explicit budgets, and report regressions without exporting SQL values.'
  s.authors = ['Elie Laloum']
  s.license = 'MIT'
  s.homepage = 'https://github.com/elie-laloum/queryledger'
  s.metadata = { 'source_code_uri' => 'https://gitlab.elielaloum.com/elielaloum/queryledger' }
  s.required_ruby_version = '>= 3.2'
  s.files = Dir['lib/**/*.rb', 'bin/*', 'README*', 'LICENSE']
  s.bindir = 'bin'
  s.executables = ['queryledger']
  s.require_paths = ['lib']
  s.add_dependency 'activesupport', '>= 7.1', '< 9'
end
