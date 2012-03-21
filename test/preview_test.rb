require "test_helper"
require "preview"

describe Preview do
  describe "retrieving a preview" do
    it "returns nil if there is no preview data" do
      Resque.redis.stubs(:hget).with("wee_printer_previews", "id").returns(nil)
      Preview.find("id").must_be :==, nil
    end

    it "returns the data if preview does exist" do
      Resque.redis.stubs(:hget).with("wee_printer_previews", "id").returns("data")
      Preview.find("id").must_be :==, "data"
    end
  end

  describe "storing a preview" do
    it "stores the url of the file against the id" do
      Resque.redis.expects(:hset).with("wee_printer_previews", "id", "/previews/id.png")
      Preview.store("id", "public/previews/id.png")
    end
  end
end