require "test_helper"
require "print_processor"

describe PrintProcessor do
  let(:pixels) do
    [1,0,0,0,0,0,0,0,
     0,1,0,0,0,0,0,0,
     0,0,1,0,0,0,0,0,
     0,0,0,1,0,0,0,0,
     0,0,0,0,1,0,0,0,
     0,0,0,0,0,1,0,0,
     0,0,0,0,0,0,1,0,
     0,0,0,0,0,0,0,1]
  end

  it "can different print processing by type" do
    PrintProcessor.for("A2-bitmap").must_be_instance_of PrintProcessor::A2Bitmap
    PrintProcessor.for("A2-raw").must_be_instance_of PrintProcessor::A2Raw
  end

  describe "when processing for A2-bitmap" do
    subject do
      PrintProcessor.for("A2-bitmap").process({"width" => 8, "height" => 8, "pixels" => pixels})
    end

    it "returns a width of 384" do
      PrintProcessor.for("A2-bitmap").width.must_equal 384
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

  describe "when processing for A2-raw" do
    subject do
      PrintProcessor.for("A2-raw").process({"width" => 8, "height" => 8, "pixels" => pixels})
    end

    let(:initialisation_commands) do
      initialisation_commands = StringIO.new
      A2Printer.new(initialisation_commands).begin(240)
      initialisation_commands.rewind
      initialisation_commands.read
    end

    it "returns a width of 384" do
      PrintProcessor.for("A2-raw").width.must_equal 384
    end

    it "sends the initialisation commands to the printer" do
      subject[0,initialisation_commands.length].must_equal initialisation_commands
    end

    it "sends the print bitmap command" do
      subject[initialisation_commands.length,2].unpack("C*").must_equal [18, 42]
    end

    it "sends the bitmap height and width" do
      subject[initialisation_commands.length+2,2].unpack("C*").must_equal [8, 1]
    end

    it "encodes the body of the image" do
      subject[(initialisation_commands.length+4)..-4].unpack("C*").must_equal [128,64,32,16,8,4,2,1]
    end
    
    it "feeds three lines after the print" do
      subject[-3..-1].unpack("C*").must_equal [10, 10, 10]
    end
    
    it "rotates the image so the bottom is printed first" do
      pixels = [0,1,1,0,0,0,0,0] + [0]*(8*7)
      data = PrintProcessor.for("A2-raw").process({"width" => 8, "height" => 8, "pixels" => pixels})
      data[(initialisation_commands.length+4)..-4].unpack("C*").must_equal [0,0,0,0,0,0,0,6]
    end
  end
end