class RemotePrinter
  def self.key(id)
    "printer/#{id}"
  end

  def self.update(params)
    Resque.redis.hset(key(params[:id]), "type", params[:type])
    Resque.redis.set("printer/ip/#{params[:ip]}", params[:id])
    Resque.redis.expire("printer/ip/#{params[:ip]}", 60)
  end

  def self.find(id)
    new(id)
  end

  def self.find_by_ip(ip)
    id = Resque.redis.get("printer/ip/#{ip}")
    find(id) if id
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def type
    Resque.redis.hget(self.class.key(@id), "type")
  end
end