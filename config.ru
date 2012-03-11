require "rubygems"
require "bundler/setup"

$LOAD_PATH.unshift(".")
require 'resque/server'
require "server"
require 'sass/plugin/rack'

Sass::Plugin.options[:template_location] = 'public/stylesheets'
use Sass::Plugin::Rack

run Rack::Cascade.new [WeePrinterServer, Rack::URLMap.new("/resque" => Resque::Server)]