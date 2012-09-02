$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "printer"
require "printer/configuration"
require "printer/print_archive"
require "printer/data_store"

redis = Printer::DataStore.redis

archives = redis.keys("printers:*:prints")
archives.each do |archive_key|
  printer_id = archive_key.split(":")[1]
  archive = Printer::PrintArchive.new(printer_id)
  puts "Processing printer ID: #{printer_id}"
  print_ids = redis.hkeys(archive_key)
  print "\tstoring #{print_ids.length} prints... "
  print_ids.each do |print_id|
    print_data = MultiJson.decode(redis.hget(archive_key, print_id))
    print_guid = print_data.delete("id")
    archive.store(print_data.merge(guid: print_guid))
  end
  puts "stored."
end
