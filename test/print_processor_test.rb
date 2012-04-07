require "test_helper"
require "print_processor"

describe PrintProcessor do
  describe "when processing for A2-bitmap" do
    subject do
      pixels = [1,0,0,0,0,0,0,0,
                0,1,0,0,0,0,0,0,
                0,0,1,0,0,0,0,0,
                0,0,0,1,0,0,0,0,
                0,0,0,0,1,0,0,0,
                0,0,0,0,0,1,0,0,
                0,0,0,0,0,0,1,0,
                0,0,0,0,0,0,0,1]
      PrintProcessor.for("A2-bitmap").process({"width" => 8, "height" => 8, "pixels" => pixels})
    end

    it "includes the size of the image" do
      subject[0,8].unpack("SS").must_equal [8,8]
    end

    it "encodes the body of the image" do
      subject[4..-1].unpack("C*").must_equal [128,64,32,16,8,4,2,1]
    end

    it "rotates the image so the bottom is printed first" do
      pixels = [0,1,1,0,0,0,0,0] + [0]*(8*7)
      data = PrintProcessor.for("A2-bitmap").process({"width" => 8, "height" => 8, "pixels" => pixels})
      data[4..-1].unpack("C*").must_equal [0,0,0,0,0,0,0,6]
    end
  end
end