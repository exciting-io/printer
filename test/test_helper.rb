require "minitest/autorun"
require "rubygems"
require "bundler"
Bundler.require(:default, :test)

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "jobs"

def fixture_path(filename)
  File.expand_path("../fixtures/#{filename}", __FILE__)
end

def url_regexp(path)
  Regexp.new(Regexp.escape("http://#{last_request.host}#{path}"))
end

require "content_store"
ContentStore.content_directory = File.expand_path("../../tmp", __FILE__)

Mocha::Configuration.prevent :stubbing_non_existent_method