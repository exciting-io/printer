require "data_store"
require "print_processor"

class RemotePrinter
  def self.key(id)
    "printers:#{id}"
  end

  def self.update(params)
    DataStore.redis.hset(key(params[:id]), "type", params[:type])
    DataStore.redis.set("ip:#{params[:ip]}", params[:id])
    DataStore.redis.expire("ip:#{params[:ip]}", 60)
  end

  def self.find(id)
    new(id)
  end

  def self.find_by_ip(ip)
    id = DataStore.redis.get("ip:#{ip}")
    find(id) if id
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def type
    DataStore.redis.hget(self.class.key(@id), "type")
  end

  def width
    PrintProcessor.for(type).width
  end
end