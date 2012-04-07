require "test_helper"
require "print_queue"
require "print_processor"
require "remote_printer"

describe PrintQueue do
  subject do
    PrintQueue.new("123")
  end

  describe "#add_print_data" do
    it "puts the json-encoded data into a redis list for that printer" do
      DataStore.redis.expects(:lpush).with("printers:123:queue", MultiJson.encode(data: "data"))
      subject.add_print_data(data: "data")
    end
  end

  describe "#data_waiting?" do
    it "returns true if data exists" do
      DataStore.redis.stubs(:llen).with("printers:123:queue").returns(1)
      subject.data_waiting?.must_equal true
    end

    it "returns false if data doesn't exist" do
      DataStore.redis.stubs(:llen).with("printers:123:queue").returns(0)
      subject.data_waiting?.must_equal false
    end
  end

  describe "#archive_and_return_print_data" do
    describe "when no data exists" do
      before do
        DataStore.redis.stubs(:lpop).with("printers:123:queue").returns(nil)
      end

      it "returns nil if no print data exists" do
        subject.archive_and_return_print_data.must_equal nil
      end

      it "doesn't put anything into the archive if no print data exists" do
        DataStore.redis.expects(:lpush).with("printers:123:archive", anything).never
        subject.archive_and_return_print_data
      end
    end

    describe "when data exists" do
      let(:data) { {"width" => 8, "height" => 8, "pixels" => []}}

      before do
        RemotePrinter.stubs(:find).with("123").returns(stub("printer", type: "A2-bitmap"))
        DataStore.redis.stubs(:lpop).with("printers:123:queue").returns(MultiJson.encode(data))
      end

      it "sends the json-decoded data through a print processor" do
        PrintProcessor.expects(:for).with("A2-bitmap").returns(processor = stub("processor"))
        processor.expects(:process).with(data).returns("data-for-printer")
        subject.archive_and_return_print_data.must_equal "data-for-printer"
      end

      it "adds the data to the archive list" do
        DataStore.redis.expects(:lpush).with("printers:123:archive", MultiJson.encode(data))
        subject.archive_and_return_print_data
      end
    end
  end
end