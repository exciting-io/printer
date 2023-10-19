require "multi_json"
require "printer/data_store"

class Printer::PrintQueue
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def enqueue(data)
    encoded_data = MultiJson.encode(data.merge(queued_at: Time.now))
    redis.lpush(key, encoded_data)
  end

  def pop
    encoded_data = redis.rpop(key)
    MultiJson.decode(encoded_data) if encoded_data
  end

  private

  def redis
    Printer::DataStore.redis
  end

  def key
    "printers:#{id}:queue"
  end
end
