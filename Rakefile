$: << File.expand_path(File.dirname(__FILE__))
STDOUT.sync=true

desc 'Default task: run all tests'
task :default => [:test]

desc "Run all tests"
task :test do
  exec "thor monk:test"
end

desc "Bootstrap project, initialize databases"
task :bootstrap do
  Rake::Task['db:clean'].invoke
  puts "Bootstrapping database...."
  system 'scripts/bootstrap.rb'

  require 'init'
  require 'spec/factory'
  puts "Putting default stuff in DB #{monk_settings(:redis)[:db]}"

  puts "Creating default admin account: loboadmin"

  admin = User.create(:name => 'loboadmin', :password => 'm316121', :password_confirmation => 'm316121', :email => 'admin@lobo.com')
  admin.tags << 'can_sanction'
  admin.tags << 'admin'
end

namespace :db do
  desc "Clean everything in DB"
  task :clean do
    require 'init'
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
    require 'init'
    [Post, Comment, User, Category, Moderation, Subscription].each do |c|
      c.all.each(&:save)
    end
    puts "Updating DB #{monk_settings(:redis)[:db]}"
    puts "There are #{User.all.count} users, #{Post.all.count} posts and #{Comment.all.count} comments in DB."
  end
end
