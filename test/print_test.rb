require "test_helper"
require "print"

describe Print do
  describe "converting back to image" do
    it "should return an image matching the given pixels" do
      print = Print.new({"width" => 8, "height" => 8, "pixels" => [0]*64})
      image = print.to_image
      image.format = "PNG"
      image.to_blob.must_equal File.binread(fixture_path("8x8-blank.png"))
    end
  end
end