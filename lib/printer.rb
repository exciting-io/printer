require "base64"

class Printer
  def initialize(id)
    @id = id
    redis.sadd("printers", @id)
  end

  def add_print_data(data)
    encoded_data = Base64.encode64(data)
    redis.lpush(printer_redis_key, encoded_data)
  end

  def data_waiting?
    redis.llen(printer_redis_key) > 0
  end

  def archive_and_return_print_data
    encoded_data = redis.lpop(printer_redis_key)
    if encoded_data
      redis.lpush(printer_archive_redis_key, encoded_data)
      Base64.decode64(encoded_data)
    end
  end

  private

  def redis
    Resque.redis
  end

  def printer_redis_key
    "printer/#{@id}"
  end

  def printer_archive_redis_key
    "printer/#{@id}/archive"
  end
end