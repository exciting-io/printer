require "printer"
require "redis"
require "redis/namespace"

module Printer::DataStore
  def self.redis_host
    ENV["REDIS_HOST"] || "localhost"
  end

  def self.redis_port
    ENV["REDIS_PORT"] || "6379"
  end

  def self.redis
    @redis ||= Redis::Namespace.new(:printer, redis: Redis.new(host: redis_host, port: redis_port))
  end
end
