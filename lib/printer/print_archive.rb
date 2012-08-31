require "multi_json"
require "printer/data_store"
require "printer/id_generator"
require "printer/print"

class Printer::PrintArchive
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def store(data)
    print_id = Printer::IdGenerator.random_id
    attributes = data.merge("created_at" => Time.now, "id" => print_id)
    Printer::DataStore.redis.hset(key, print_id, MultiJson.encode(attributes))
    Printer::Print.new(attributes)
  end

  def find(print_id)
    data = Printer::DataStore.redis.hget(key, print_id)
    Printer::Print.new(MultiJson.decode(data)) if data
  end

  def ids
    Printer::DataStore.redis.hkeys(key)
  end

  def all
    Printer::DataStore.redis.hvals(key).map { |d| Printer::Print.new(MultiJson.decode(d)) }
  end

  private

  def key
    "printers:#{id}:prints"
  end
end
