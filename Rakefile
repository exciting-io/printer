require "rubygems"
require "bundler/setup"

load "tasks/resque.rake"

task "resque:setup" => :environment
task :environment do
  $LOAD_PATH.unshift "lib"
  require "jobs"
end