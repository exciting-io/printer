require "rubygems"
require "bundler/setup"

$LOAD_PATH.unshift(".")
require 'resque/server'
require "server"

run Rack::Cascade.new [WeePrinterBackendServer, Rack::URLMap.new("/resque" => Resque::Server)]