require "data_mapper"
require 'dm-timestamps'
require "printer/data_store"
require "resque"

# DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/printer')
DataMapper.repository(:default).adapter.resource_naming_convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule

# Load all DataMapper models
require "printer/print"

DataMapper.finalize
DataMapper.auto_upgrade!

Resque.redis = "#{Printer::DataStore.redis_host}:#{Printer::DataStore.redis_port}"
