unless File.exist?('Gemfile')
  File.write('Gemfile', <<-GEMFILE)
    source 'https://rubygems.org'
    gem 'rails', '4.1.8'
    gem 'pg'
  GEMFILE

  system 'bundle'
end

require 'bundler'
Bundler.setup(:default)

require 'active_record'
require 'minitest/autorun'
require 'logger'

`dropdb rails_bug`
`createdb rails_bug`

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'rails_bug')
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :posts, force: true  do |t|
  end
end

class Post < ActiveRecord::Base
end

Post.create
puts "Posts: #{Post.pluck(:id)}"

ActiveRecord::Schema.define do
  # default sequence should be posts_id_seq
  #
  execute 'CREATE SEQUENCE new_posts_sequence start 101;'
  execute <<-SQL
    ALTER TABLE "posts" ALTER COLUMN "id" set DEFAULT NEXTVAL('new_posts_sequence');
  SQL
end

class Post < ActiveRecord::Base
  self.sequence_name = 'new_posts_sequence'
end

Post.create

puts
puts
puts "Posts count should be 2 and is: #{Post.count}"
puts "Post IDs should be 1 and 101 and are: #{Post.pluck(:id)}"
