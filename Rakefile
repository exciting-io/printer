require "rubygems"
require "bundler/setup"

load "tasks/resque.rake"

task "resque:setup" => :environment
task :environment do
  $LOAD_PATH.unshift "lib"
  require "jobs"
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs = ["test"]
  t.pattern = "test/*_test.rb"
end

task :default => :test