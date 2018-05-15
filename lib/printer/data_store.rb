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

  def self.redis_url
    ENV['REDIS_URL']
  end

  def self.redis
    redis = if redis_url
      Redis.new(url: redis_url)
    else
      Redis.new(host: redis_host, port: redis_port)
    end
    @redis ||= Redis::Namespace.new(:printer, redis: redis)
  end
end
