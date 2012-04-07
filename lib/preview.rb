require "data_store"

class Preview
  def self.find(id)
    data = DataStore.redis.hget('previews', id)
    new(data) if data
  end

  def self.store(id, url, path)
    relative_url = path.gsub(/^public/, '')
    data = [url, relative_url]
    DataStore.redis.hset('previews', id, MultiJson.encode(data))
  end

  attr_reader :original_url, :image_path

  def initialize(encoded_data)
    @original_url, @image_path = MultiJson.decode(encoded_data)
  end
end