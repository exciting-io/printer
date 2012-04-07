class RemotePrinter
  def self.key(id)
    "printer/#{id}"
  end

  def self.update(params)
    Resque.redis.hset(key(params[:id]), "type", params[:type])
  end

  def self.find(id)
    new(id)
  end

  def initialize(id)
    @id = id
  end

  def type
    Resque.redis.hget(self.class.key(@id), "type")
  end
end