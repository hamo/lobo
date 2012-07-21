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
  puts "Bootstrapping database...."
  system 'scripts/bootstrap.rb'
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
    Rake::Task['db:clean'].invoke
    Rake::Task['bootstrap'].invoke

    require 'init'
    require 'spec/factory'
    puts "Putting default stuff in DB #{monk_settings(:redis)[:db]}"

    puts "Creating default admin account: loboadmin:admin"

    User.create(:name => 'loboadmin', :password => 'admin', :password_confirmation => 'admin', :email => 'admin@lobo.com')
    User.first(:name => 'loboadmin').tags << 'can_sanction'
    User.first(:name => 'loboadmin').tags << 'admin'

    75.times { Fabricate(:comment) }

    puts "There are #{User.all.count} users, #{Post.all.count} posts and #{Comment.all.count} comments in DB."
  end

  desc 'Remake indexes after changing models'
  task :migrate do
    require 'init'
    Post.all.each(&:save)
    Comment.all.each(&:save)
    User.all.each(&:save)
    Category.all.each(&:save)
    puts "Updating DB #{monk_settings(:redis)[:db]}"
    puts "There are #{User.all.count} users, #{Post.all.count} posts and #{Comment.all.count} comments in DB."
  end
end
