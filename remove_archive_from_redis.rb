$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "printer"
require "printer/configuration"
require "printer/print_archive"
require "printer/data_store"

redis = Printer::DataStore.redis

archives = redis.keys("printers:*:prints")
archives.each do |archive_key|
  redis.del(archive_key)
  puts "Removed archive #{archive_key}"
end
