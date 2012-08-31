require "printer"
require "redis"
require "redis/namespace"

module Printer::DataStore
  def self.redis
    @redis ||= Redis::Namespace.new(:printer, redis: Redis.new)
  end
end
