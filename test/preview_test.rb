require "test_helper"
require "printer/preview"

describe Printer::Preview do
  describe "retrieving a preview" do
    it "returns nil if there is no preview data" do
      Printer::DataStore.redis.stubs(:hget).with("previews", "id").returns(nil)
      Printer::Preview.find("id").must_equal nil
    end

    it "returns the data if preview does exist" do
      Printer::DataStore.redis.stubs(:hget).with("previews", "id").returns(MultiJson.encode({original_url: "url", image_path: "/previews/id.png"}))
      data = Printer::Preview.find("id")
      data.original_url.must_equal "url"
      data.image_path.must_equal "/previews/id.png"
    end
  end

  describe "storing a preview" do
    it "stores the original url and url of the file against the id" do
      Printer::DataStore.redis.expects(:hset).with("previews", "id", MultiJson.encode({original_url: "url", image_path: "/previews/id.png"}))
      Printer::Preview.store("id", "url", {image_path: "public/previews/id.png"})
    end
  end
end
