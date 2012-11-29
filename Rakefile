$: << File.expand_path(File.dirname(__FILE__))
STDOUT.sync=true

require 'init'

desc 'Default task: run all tests'
task :default => [:test]

desc "Run all tests"
task :test do
  exec "thor monk:test"
end

#desc 'regenerate sprites'
task :sprite do
  require 'sprite_factory'
  SpriteFactory.run!('app/views/css/sprite', 
                     :layout => :packed, 
                     :library => :chunkypng,
                     :style => :sass,
                     :pngcrush => false,
                     :selector => '.sprite.',
                     :csspath => '/images',
                     :output_image => 'public/images/sprite.png',
                     :output_style => 'app/views/css/_sprite.sass',
                    )
end

desc 'compile js'
task :js do
  require 'coffee-script'
  Dir["app/views/js/*.coffee"].each {|f|
    out = "public/js/" + File.basename(f).sub(/\.coffee\Z/, '.js')
    js = CoffeeScript.compile File.read(f)
    puts "\e[33m#{f}\e[m compiled to \e[32m#{out}\e[m"
    File.open(out, 'w'){|f| f.puts js}
  }
end

#require "redis-search"
namespace :redis_search do
  desc "Redis-Search index data to Redis"
  task :index do
    tm = Time.now
    count = 0
    puts "redis-search index".upcase.rjust(120)
    puts "-"*120
    puts "Now indexing search to Redis...".rjust(120)
    puts ""
    Redis::Search.indexed_models.each do |klass|
      print "[#{klass.to_s}]"
      if klass.superclass.to_s == "ActiveRecord::Base"
        klass.find_in_batches(:batch_size => 1000) do |items|
          items.each do |item|
            item.redis_search_index_create
            item = nil
            count += 1
            print "."
          end
        end
      elsif klass.included_modules.map(&:to_s).include?("Mongoid::Document") or klass.ancestors.include?(Ohm::Model)
        klass.all.each do |item|
          item.redis_search_index_create
          item = nil
          count += 1
          print "."
        end
      else
        puts "skiped, not support this ORM in current."
      end
      puts ""
    end
    puts ""
    puts "-"*120
    puts "Indexed #{count} rows | Time spend: #{(Time.now - tm)}s".rjust(120)
    puts "Rebuild Index done.".rjust(120)
  end
end

desc "Bootstrap project, initialize databases"
task :bootstrap do
  Rake::Task['db:clean'].invoke
  puts "Bootstrapping database...."
  system 'scripts/bootstrap.rb'

  require 'spec/factory'
  puts "Putting default stuff in DB #{monk_settings(:redis)[:db]}"

  puts "Creating default admin account: loboadmin"

  admin = User.create(:name => 'loboadmin', :password => 'm316121', :password_confirmation => 'm316121', :email => 'admin@lobo.com')
  admin.add_tag 'can_sanction'
  admin.add_tag 'admin'
end

namespace :db do
  desc "Clean everything in DB"
  task :clean do
    print "\e[31;1mWarning\e[m: all data in db will be lost! Type YES to confirm: "
    answer = STDIN.gets.strip
    if answer != 'YES'
      puts 'Abort.'
      exit
    end
    puts "Removing everything in DB #{monk_settings(:redis)[:db]}"
    Ohm.flush
  end

  desc "Fill in default data"
  task :fill do
    Rake::Task['bootstrap'].invoke

    # 10 posts so that loboadmin can report ...
    10.times { Fabricate(:content_post, :author => User.with(:name, 'loboadmin')) }

    75.times { Fabricate(:comment) }

    puts "There are #{User.all.count} users, #{Post.all.count} posts and #{Comment.all.count} comments in DB."
  end

  desc 'Remake indexes after changing models'
  task :migrate do
    [Post, Comment, User, Category, Moderation, Subscription].each do |c|
      c.all.each(&:save)
    end
    puts "Updating DB #{monk_settings(:redis)[:db]}"
    puts "There are #{User.all.count} users, #{Post.all.count} posts and #{Comment.all.count} comments in DB."
  end
end
