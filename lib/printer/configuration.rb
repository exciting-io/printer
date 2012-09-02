require "data_mapper"
require 'dm-timestamps'

# DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/printer')
DataMapper.repository(:default).adapter.resource_naming_convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule

# Load all DataMapper models
require "printer/print"

DataMapper.finalize
DataMapper.auto_upgrade!
