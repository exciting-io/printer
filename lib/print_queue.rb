require "multi_json"
require "print_processor"
require "remote_printer"
require "data_store"

class PrintQueue
  def initialize(id)
    @id = id
    redis.sadd("printers", @id)
  end

  def add_print_data(data)
    encoded_data = MultiJson.encode(data)
    redis.lpush(print_queue_redis_key, encoded_data)
  end

  def data_waiting?
    redis.llen(print_queue_redis_key) > 0
  end

  def archive_and_return_print_data
    encoded_data = redis.lpop(print_queue_redis_key)
    if encoded_data
      redis.lpush(print_archive_redis_key, encoded_data)
      PrintProcessor.for(remote_printer.type).process(MultiJson.decode(encoded_data))
    end
  end

  private

  def remote_printer
    RemotePrinter.find(@id)
  end

  def redis
    DataStore.redis
  end

  def print_queue_redis_key
    "printers:#{@id}:queue"
  end

  def print_archive_redis_key
    "printers:#{@id}:archive"
  end
end