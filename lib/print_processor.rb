module PrintProcessor
  autoload :A2Bitmap, "print_processor/a2_bitmap"
  autoload :A2Raw, "print_processor/a2_raw"

  def self.for(printer)
    klass = case printer.type
    when "A2-bitmap"
      A2Bitmap
    when "A2-raw"
      A2Raw
    end
    klass.new(printer.darkness, printer.flipped)
  end
end