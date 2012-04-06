class RemotePrinter
  def self.update(params)
    Resque.redis.hset("printer/#{params[:id]}", "type", params[:type])
  end
end