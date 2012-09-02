require "multi_json"
require "printer/data_store"
require "printer/id_generator"
require "printer/print"

class Printer::PrintArchive
  attr_reader :id, :prints

  def initialize(id)
    @id = id
    @prints = Printer::Print.all(printer_guid: id)
  end

  def store(data)
    Printer::Print.create(data.merge(printer_guid: id))
  end

  def find(print_guid)
    prints.first(guid: print_guid)
  end
end
