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
  t.pattern = "test/**/*_test.rb"
end

task :default => [:test, "test:javascript"]

namespace :data do
  desc "Clear out the data"
  task :reset do
    $LOAD_PATH.unshift "lib"
    require "data_store"
    DataStore.redis.keys.each { |k| DataStore.redis.del k }
  end
end

namespace :test do
  desc "Run javascript tests"
  task :javascript => :environment do
    phantomjs_requirement = Gem::Requirement.new(">= 1.3.0")
    phantomjs_version = Gem::Version.new(`phantomjs --version`.strip) rescue Gem::Version.new("0.0.0")
    unless phantomjs_requirement.satisfied_by?(phantomjs_version)
      STDERR.puts "Your version of phantomjs (v#{phantomjs_version}) is not compatible with the current phantom-driver.js."
      STDERR.puts "Please upgrade your version of phantomjs to #{phantomjs_requirement} and re-run this task."
      exit 1
    end

    require "webrick"
    test_port = 3100
    server = WEBrick::HTTPServer.new(:Port => test_port, :DocumentRoot => File.expand_path("../test/javascript", __FILE__), :AccessLog => [], :Logger => WEBrick::Log.new("/dev/null", 7))
    server.mount("/app", WEBrick::HTTPServlet::FileHandler, File.expand_path("../public", __FILE__))
    server_thread = Thread.new do
      puts "Starting the server"
      server.start
    end

    runner = "http://127.0.0.1:#{test_port}/test.html"
    phantom_driver = File.expand_path('../test/javascript/phantom-driver.js', __FILE__)

    command = "phantomjs #{phantom_driver} #{runner}"

    IO.popen(command) do |test|
      puts test.read
    end

    # grab the exit status of phantomjs
    # this will be the result of the tests
    # it is important to grab it before we
    # exit the server otherwise $? will be overwritten.
    test_result = $?.exitstatus

    puts "Stopping the server"
    server.stop
    server_thread.join

    exit test_result
  end
end