$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

require 'rubygems'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'
require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'statum'

namespace :db do

  desc "Migrate the database"
  task :migrate do
    DataMapper.auto_migrate!
  end

  desc "Add some test users"
  task :testusers do
    t = Team.new
    t.name = "Test"
    t.description = "This is a test team"
    t.save!
    t = Team.first(:name => "Test")
    if t.users.create(
      :login    => "test",
      :name     => "Test User",
      :email    => "test@example.com",
      :password => "test")
      puts "User created"
    else
     puts t.errors
    end
  end
end

task :default => :help

desc "Run specs"
task :spec do
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = './spec/**/*_spec.rb'
  end
end

desc "Run IRB console with app environment"
task :console do
  puts "Loading development console..."
  system("irb -r ./lib/statum.rb")
end

desc "Show help menu"
task :help do
  puts "Available rake tasks: "
  puts "rake console - Run a IRB console with all enviroment loaded"
  puts "rake spec - Run specs and calculate coverage"
end
