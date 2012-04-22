require "multi_json"
require "data_store"

class PrintQueue
  attr_reader :id

  def initialize(id)
    @id = id
  end

  def enqueue(data)
    encoded_data = MultiJson.encode(data.merge(queued_at: Time.now))
    redis.lpush(key, encoded_data)
  end

  def pop
    encoded_data = redis.lpop(key)
    MultiJson.decode(encoded_data) if encoded_data
  end

  private

  def redis
    DataStore.redis
  end

  def key
    "printers:#{id}:queue"
  end
end