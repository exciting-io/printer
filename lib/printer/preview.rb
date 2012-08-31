require "printer/data_store"

class Printer::Preview
  def self.find(id)
    data = Printer::DataStore.redis.hget('previews', id)
    new(MultiJson.decode(data)) if data
  end

  def self.store(id, url, data)
    if data[:image_path]
      relative_url = data[:image_path].gsub(/^public/, '')
      data = {original_url: url, image_path: relative_url}
    else
      data = {original_url: url, error: data[:error]}
    end
    Printer::DataStore.redis.hset('previews', id, MultiJson.encode(data))
  end

  attr_reader :original_url, :image_path, :error

  def initialize(attributes)
    @original_url = attributes["original_url"]
    @image_path = attributes["image_path"]
    @error = attributes["error"]
  end
end
