class Preview
  def self.find(id)
    Resque.redis.hget('wee_printer_previews', id)
  end

  def self.store(id, path)
    Resque.redis.hset('wee_printer_previews', id, path.gsub(/^public/, ''))
  end
end