class Preview
  def self.find(id)
    data = Resque.redis.hget('wee_printer_previews', id)
    new(data) if data
  end

  def self.store(id, url, path)
    relative_url = path.gsub(/^public/, '')
    data = [url, relative_url]
    Resque.redis.hset('wee_printer_previews', id, MultiJson.encode(data))
  end

  attr_reader :original_url, :image_path

  def initialize(encoded_data)
    @original_url, @image_path = MultiJson.decode(encoded_data)
  end
end