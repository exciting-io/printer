require "test_helper"
require "remote_printer"

describe RemotePrinter do
  describe "updating" do
    it "stores the printer data" do
      Resque.redis.expects(:hset).with("printer/1", "type", "printer-type")
      RemotePrinter.update(id: "1", type: "printer-type")
    end
  end

  describe "retrieving" do
    it "returns the data for the stored printer" do
      Resque.redis.stubs(:hget).with("printer/1", "type").returns("printer-type")
      RemotePrinter.find("1").type.must_equal "printer-type"
    end
  end
end