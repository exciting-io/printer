require "test_helper"
require "remote_printer"

describe RemotePrinter do
  describe "updating" do
    it "stores the printer data" do
      Resque.redis.expects(:hset).with("printer/1", "type", "printer-type")
      RemotePrinter.update(id: "1", type: "printer-type")
    end
  end
end