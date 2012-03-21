require "test_helper"
require "printer"

describe Printer do
  subject do
    Printer.new(123)
  end

  describe "#add_print_data" do
    it "puts the base64-encoded data into a redis list for that printer" do
      Resque.redis.expects(:lpush).with("printer/123", Base64.encode64("data"))
      subject.add_print_data("data")
    end
  end

  describe "#data_waiting?" do
    it "returns true if data exists" do
      Resque.redis.stubs(:llen).with("printer/123").returns(1)
      subject.data_waiting?.must_be :==, true
    end

    it "returns false if data doesn't exist" do
      Resque.redis.stubs(:llen).with("printer/123").returns(0)
      subject.data_waiting?.must_be :==, false
    end
  end

  describe "#archive_and_return_print_data" do
    it "returns nil if no print data exists" do
      Resque.redis.stubs(:lpop).with("printer/123").returns(nil)
      subject.archive_and_return_print_data.must_be :==, nil
    end

    it "returns the base64-decoded data if some exists" do
      Resque.redis.stubs(:lpop).with("printer/123").returns(Base64.encode64("data"))
      subject.archive_and_return_print_data.must_be :==, "data"
    end

    it "adds the data to the archive list if some is popped" do
      Resque.redis.stubs(:lpop).with("printer/123").returns(Base64.encode64("data"))
      Resque.redis.expects(:lpush).with("printer/123/archive", Base64.encode64("data"))
      subject.archive_and_return_print_data
    end
  end
end