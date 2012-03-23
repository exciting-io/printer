require "test_helper"
require "preview"

describe Preview do
  describe "retrieving a preview" do
    it "returns nil if there is no preview data" do
      Resque.redis.stubs(:hget).with("wee_printer_previews", "id").returns(nil)
      Preview.find("id").must_equal nil
    end

    it "returns the data if preview does exist" do
      Resque.redis.stubs(:hget).with("wee_printer_previews", "id").returns(MultiJson.encode(["url", "/previews/id.png"]))
      data = Preview.find("id")
      data.original_url.must_equal "url"
      data.image_path.must_equal "/previews/id.png"
    end
  end

  describe "storing a preview" do
    it "stores the original url and url of the file against the id" do
      Resque.redis.expects(:hset).with("wee_printer_previews", "id", MultiJson.encode(["url", "/previews/id.png"]))
      Preview.store("id", "url", "public/previews/id.png")
    end
  end
end