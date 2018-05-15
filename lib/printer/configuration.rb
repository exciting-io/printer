require "data_mapper"
require 'dm-timestamps'
require "resque"

# DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/printer')
DataMapper.repository(:default).adapter.resource_naming_convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule

# Load all DataMapper models
require "printer/print"

DataMapper.finalize
DataMapper.auto_upgrade!

if ENV["REDIS_URL"]
  Resque.redis = Redis.new(url: ENV["REDUS_URL"])
elsif ENV["REDIS_HOST"] && ENV["REDIS_PORT"]
  Resque.redis = "#{ENV["REDIS_HOST"]}:#{ENV["REDIS_PORT"]}"
end
