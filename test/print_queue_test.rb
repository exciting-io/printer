require "test_helper"
require "printer/remote_printer"

describe Printer::PrintQueue do
  subject do
    Printer::PrintQueue.new("printer-123")
  end

  let(:redis) { Printer::DataStore.redis }

  describe "#enqueue" do
    it "puts the json-encoded data with a timestamp into a redis list for that printer" do
      redis.expects(:lpush).with("printers:printer-123:queue", MultiJson.encode(data: "data", queued_at: Time.now))
      subject.enqueue(data: "data")
    end
  end

  describe "#pop" do
    describe "when no data exists" do
      before do
        redis.stubs(:rpop).with("printers:printer-123:queue").returns(nil)
      end

      it "returns nil if no print data exists" do
        subject.pop.must_be_nil
      end
    end

    describe "when data exists" do
      let(:data) { {"width" => 8, "height" => 8, "pixels" => []}}

      before do
        Printer::RemotePrinter.stubs(:find).with("printer-123").returns(stub("printer", type: "A2-bitmap"))
      end

      it "removes the print from the queue" do
        redis.expects(:rpop).with("printers:printer-123:queue")
        subject.pop
      end

      it "returns the json-decoded data" do
        redis.stubs(:rpop).with("printers:printer-123:queue").returns(MultiJson.encode(data))
        subject.pop.must_equal data
      end
    end
  end
end
