require "printer/data_store"
require "printer/print_queue"
require "printer/print_processor"
require "printer/print_archive"

class Printer::RemotePrinter
  def self.find(id)
    new(id)
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def update(params)
    attributes_to_store = params.inject([]) { |a, (k,v)| a + [k.to_s,v] }
    redis.hmset(key, *attributes_to_store) if attributes_to_store.any?
  end

  def type
    redis.hget(key, "type")
  end

  def darkness
    stored_value = redis.hget(key, "darkness")
    if stored_value
      stored_value.to_i
    elsif type.split(".").length >= 2
      type.split(".")[1].to_i
    else
      240
    end
  end

  def flipped
    stored_value = redis.hget(key, "flipped")
    if stored_value
      stored_value == "true"
    elsif type.split(".").length == 3
      true
    else
      false
    end
  end

  def version
    redis.hget(key, "version")
  end

  def width
    Printer::PrintProcessor.for(type).width
  end

  def data_to_print
    print_info = queue.pop
    if print_info
      print = archive.find(print_info["print_id"])
      if print
        data = {"width" => print.width, "height" => print.height, "pixels" => print.pixels}
        Printer::PrintProcessor.for(self).process(data)
      end
    end
  end

  def add_print(data)
    print = archive.store(data)
    queue.enqueue(print_id: print.guid)
  end

  def all_prints(page=1, per_page=10)
    archive.prints(page, per_page)
  end

  def total_prints
    archive.count
  end

  def find_print(print_id)
    archive.find(print_id)
  end

  private

  def redis
    Printer::DataStore.redis
  end

  def queue
    Printer::PrintQueue.new(id)
  end

  def archive
    Printer::PrintArchive.new(id)
  end

  def key
    "printers:#{id}"
  end
end
