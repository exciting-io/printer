require "multi_json"
require "printer/data_store"
require "printer/id_generator"
require "printer/print"

class Printer::PrintArchive
  attr_reader :id

  def initialize(id)
    @id = id
    @all_prints = Printer::Print.all(printer_guid: id)
  end

  def store(data)
    Printer::Print.create(data.merge(printer_guid: id))
  end

  def find(print_guid)
    @all_prints.first(guid: print_guid)
  end

  def prints(page=1, page_size=10)
    @all_prints.all(order: [ :created_at.desc ], limit: page_size, offset: (page - 1) * page_size)
  end

  def count
    @all_prints.count
  end
end
