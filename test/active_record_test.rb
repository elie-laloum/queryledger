require 'minitest/autorun'
require 'active_record'
require 'tmpdir'
require 'query_ledger'
require 'query_ledger/rspec'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.define do
  create_table(:authors) { |t| t.string :name }
  create_table(:posts) { |t| t.integer :author_id; t.string :title }
end
class Author < ActiveRecord::Base
  has_many :posts
end
class Post < ActiveRecord::Base
  belongs_to :author
end

class ActiveRecordTest < Minitest::Test
  include RSpec::Matchers
  def setup
    Post.delete_all
    Author.delete_all
    3.times { |i| Author.create!(name: "Author #{i}").posts.create!(title: 'A post') }
  end
  def test_real_n_plus_one_and_preload_correction
    bad = QueryLedger.capture { Author.all.each { |a| a.posts.to_a } }
    good = QueryLedger.capture { Author.includes(:posts).each { |a| a.posts.to_a } }
    assert_equal 4, bad['count']
    assert_equal 2, good['count']
    refute QueryLedger.compare(bad, { 'max' => 2 })['passed']
    assert QueryLedger.compare(good, { 'max' => 2 })['passed']
  end
  def test_rspec_block_matcher_against_real_queries
    Dir.mktmpdir do |dir|
      file = File.join(dir, 'budgets.json')
      QueryLedger.atomic_write(file, { 'schema_version' => 1, 'budgets' => { 'authors' => { 'max' => 2 } } })
      expect { Author.includes(:posts).each { |a| a.posts.to_a } }.to stay_within_query_budget('authors', baseline: file)
      assert_raises(RSpec::Expectations::ExpectationNotMetError) do
        expect { Author.all.each { |a| a.posts.to_a } }.to stay_within_query_budget('authors', baseline: file)
      end
    end
  end
end
