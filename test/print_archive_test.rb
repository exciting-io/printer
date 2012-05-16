require "test_helper"
require "print_archive"

describe PrintArchive do
  subject do
    PrintArchive.new("printer-id")
  end

  let(:data) do
    {width: 8, height: 8, pixels: []}
  end

  describe "storing a print" do
    before do
      IdGenerator.stubs(:random_id).returns("random-print-id")
    end

    it "stores the print data" do
      data_with_id_and_timestamps = data.merge(created_at: Time.now, id: "random-print-id")
      DataStore.redis.expects(:hset).with("printers:printer-id:prints", "random-print-id", MultiJson.encode(data_with_id_and_timestamps))
      subject.store(width: 8, height: 8, pixels: [])
    end

    it "returns a Print instance for that data" do
      print = subject.store("width" => 8, "height" => 8, "pixels" => [])
      print.width.must_equal 8
      print.height.must_equal 8
      print.pixels.must_equal []
      print.id.must_equal "random-print-id"
    end
  end

  describe "retrieving a print" do
    it "returns a Print" do
      DataStore.redis.stubs(:hget).with("printers:printer-id:prints", "random-print-id").returns(MultiJson.encode(data.merge(id: "random-print-id")))
      print = subject.find("random-print-id")
      print.width.must_equal 8
      print.height.must_equal 8
      print.pixels.must_equal []
      print.id.must_equal "random-print-id"
    end

    it "returns nil if the print didn't exist" do
      DataStore.redis.stubs(:hget).returns(nil)
      subject.find("random-print-id").must_be_nil
    end
  end

  describe "retrieving print ids" do
    it "returns all print IDs" do
      DataStore.redis.stubs(:hkeys).with("printers:printer-id:prints").returns(["abc123", "def456"])
      ids = subject.ids
      ids.must_equal ["abc123", "def456"]
    end
  end

  describe "retrieving all prints" do
    it "returns all Prints" do
      DataStore.redis.stubs(:hvals).with("printers:printer-id:prints").returns([MultiJson.encode(data.merge(id: "1")), MultiJson.encode(data.merge(id: "2"))])
      prints = subject.all
      prints.length.must_equal 2
      prints[0].id.must_equal "1"
      prints[1].id.must_equal "2"
    end
  end
end