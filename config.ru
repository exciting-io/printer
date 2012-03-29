require "rubygems"
require "bundler/setup"

$LOAD_PATH.unshift("lib")
require 'resque/server'
require "backend_server"
require 'sass/plugin/rack'

Sass::Plugin.options[:template_location] = 'public/stylesheets'
use Sass::Plugin::Rack

run Rack::Cascade.new [PrinterBackendServer, Rack::URLMap.new("/resque" => Resque::Server)]