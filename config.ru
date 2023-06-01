require "rubygems"
require "bundler/setup"

$LOAD_PATH.unshift("lib")
require "printer"
require "printer/configuration"
require 'sass/plugin/rack'

Sass::Plugin.options[:template_location] = 'public/stylesheets'
use Sass::Plugin::Rack

use Rack::MethodOverride

if ENV["RESQUE_SERVER"]
  require 'resque/server'
  run Rack::Cascade.new [Printer::BackendServer::App, Rack::Directory.new('public'), Rack::URLMap.new("/resque" => Resque::Server)]
else
  run Printer::BackendServer::App
end
