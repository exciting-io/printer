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

  def stub_printer(type, darkness=240, flipped=false)
    stub("printer", type: type, darkness: darkness, flipped: flipped)
  end

  it "can different print processing by type" do
    PrintProcessor.for(stub_printer("A2-bitmap")).must_be_instance_of PrintProcessor::A2Bitmap
    PrintProcessor.for(stub_printer("A2-raw")).must_be_instance_of PrintProcessor::A2Raw
  end

  it "passes printer darkness and flipped to the constructor of the print processor" do
    PrintProcessor::A2Bitmap.expects(:new).with(123, true)
    PrintProcessor.for(stub_printer("A2-bitmap", 123, true))
  end

  describe "when processing for A2-bitmap" do
    subject do
      PrintProcessor.for(stub_printer("A2-bitmap")).process({"width" => 8, "height" => 8, "pixels" => pixels})
    end

    it "returns a width of 384" do
      PrintProcessor.for(stub_printer("A2-bitmap")).width.must_equal 384
    end

    it "includes the size of the image" do
      subject[0,8].unpack("SS").must_equal [8,8]
    end

    it "encodes the body of the image" do
      subject[4..-1].unpack("C*").must_equal [128,64,32,16,8,4,2,1]
    end

    it "rotates the image so the bottom is printed first" do
      pixels = [0,1,1,0,0,0,0,0] + [0]*(8*7)
      data = PrintProcessor.for(stub_printer("A2-bitmap")).process({"width" => 8, "height" => 8, "pixels" => pixels})
      data[4..-1].unpack("C*").must_equal [0,0,0,0,0,0,0,6]
    end
  end

  describe "when processing for A2-raw" do
    subject do
      PrintProcessor.for(stub_printer("A2-raw")).process({"width" => 8, "height" => 8, "pixels" => pixels})
    end

    let(:initialisation_commands) do
      initialisation_commands = StringIO.new
      A2Printer.new(initialisation_commands).begin(240)
      initialisation_commands.rewind
      initialisation_commands.read
    end

    it "returns a width of 384" do
      PrintProcessor.for(stub_printer("A2-raw")).width.must_equal 384
    end

    it "sends the initialisation commands to the printer" do
      subject[0,initialisation_commands.length].must_equal initialisation_commands
    end

    it "sends the appropriate heat time based on the first argument" do
      commands = StringIO.new
      A2Printer.new(commands).begin(150)
      commands.rewind

      data = PrintProcessor.for(stub_printer("A2-raw", 150)).process({"width" => 8, "height" => 8, "pixels" => pixels})
      data[0, commands.length].must_equal commands.read
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
      data = PrintProcessor.for(stub_printer("A2-raw")).process({"width" => 8, "height" => 8, "pixels" => pixels})
      data[(initialisation_commands.length+4)..-4].unpack("C*").must_equal [0,0,0,0,0,0,0,6]
    end

    it "doesn't rotate the image if a flipped parameter is given" do
      commands = StringIO.new
      A2Printer.new(commands).begin(150)
      commands.rewind

      pixels = [0,1,1,0,0,0,0,0] + [0]*(8*7)
      data = PrintProcessor.for(stub_printer("A2-raw", 240, true)).process({"width" => 8, "height" => 8, "pixels" => pixels})
      data[(initialisation_commands.length+4)..-4].unpack("C*").must_equal [96,0,0,0,0,0,0,0]
    end
  end
end