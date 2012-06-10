require "rubygems"
require "bundler/setup"

$LOAD_PATH.unshift("lib")
require "backend_server"
require 'sass/plugin/rack'

Sass::Plugin.options[:template_location] = 'public/stylesheets'
use Sass::Plugin::Rack

use Rack::MethodOverride

if ENV["RESQUE_SERVER"]
  require 'resque/server'
  run Rack::Cascade.new [BackendServer::App, Rack::URLMap.new("/resque" => Resque::Server)]
else
  run BackendServer::App
end