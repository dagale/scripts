#!/usr/bin/env ruby

require 'rubygems'
require 'sqlite3'

nb_output = `newsbeuter -x reload`

db = SQLite3::Database.new( '/Users/danielgale/.newsbeuter/cache.db')
db.results_as_hash = true

ary = db.execute( "SELECT id, pubDate, title, author, url,content FROM rss_item;")

ary.each do |row|
	printf "%s| %s| %s| %s\n",row['id'],row['title'],row['author'],row['url']
end
