require 'active_record'
require_relative '../lib/query_ledger'
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table(:authors) { |t| t.string :name }
  create_table(:posts) { |t| t.integer :author_id }
end
class Author < ActiveRecord::Base
  has_many :posts
end
class Post < ActiveRecord::Base
  belongs_to :author
end
3.times { |i| Author.create!(name: "Author #{i}").posts.create! }
bad = QueryLedger.capture { Author.all.each { |a| a.posts.to_a } }
good = QueryLedger.capture { Author.includes(:posts).each { |a| a.posts.to_a } }
puts QueryLedger.message(QueryLedger.compare(bad, { 'max' => 2 }, key: 'Before preload'))
puts QueryLedger.message(QueryLedger.compare(good, { 'max' => 2 }, key: 'After preload'))
abort 'Unexpected demonstration result' unless bad['count'] == 4 && good['count'] == 2
