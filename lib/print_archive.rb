require "multi_json"
require "data_store"
require "id_generator"
require "print"

class PrintArchive
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def store(data)
    print_id = IdGenerator.random_id
    attributes = data.merge("created_at" => Time.now, "id" => print_id)
    DataStore.redis.hset(key, print_id, MultiJson.encode(attributes))
    Print.new(attributes)
  end

  def find(print_id)
    data = DataStore.redis.hget(key, print_id)
    Print.new(MultiJson.decode(data)) if data
  end

  def ids
    DataStore.redis.hkeys(key)
  end

  def all
    DataStore.redis.hvals(key).map { |d| Print.new(MultiJson.decode(d)) }
  end

  private

  def key
    "printers:#{id}:prints"
  end
end