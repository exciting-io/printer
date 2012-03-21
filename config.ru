require "rubygems"
require "bundler/setup"

$LOAD_PATH.unshift("lib")
require 'resque/server'
require "backend_server"

run Rack::Cascade.new [WeePrinterBackendServer, Rack::URLMap.new("/resque" => Resque::Server)]