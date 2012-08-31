require "test_helper"
require "printer/print"

describe Printer::Print do
  describe "converting back to image" do
    it "should return an image matching the given pixels" do
      print = Printer::Print.new({"width" => 8, "height" => 8, "pixels" => [0]*64})
      image = print.to_image
      image.format = "PNG"
      image.to_blob.must_equal png_image(8, 8, [0]*(8*8)).to_blob
    end
  end
end
