require "base64"

class PrintQueue
  def initialize(id)
    @id = id
    redis.sadd("printers", @id)
  end

  def add_print_data(data)
    encoded_data = Base64.encode64(data)
    redis.lpush(print_queue_redis_key, encoded_data)
  end

  def data_waiting?
    redis.llen(print_queue_redis_key) > 0
  end

  def archive_and_return_print_data
    encoded_data = redis.lpop(print_queue_redis_key)
    if encoded_data
      redis.lpush(print_archive_redis_key, encoded_data)
      Base64.decode64(encoded_data)
    end
  end

  private

  def redis
    Resque.redis
  end

  def print_queue_redis_key
    "printer/#{@id}/queue"
  end

  def print_archive_redis_key
    "printer/#{@id}/archive"
  end
end