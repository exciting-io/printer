require "jobs/image_to_bytes"

class Jobs::PreparePage
  def self.queue
    :wee_printer_prepare_page
  end

  def self.perform(printer_id, url)
    output_filename = "tmp/test.png"
    puts "HERE"
    cmd = "phantomjs rasterise.js #{url} #{output_filename}"
    puts "Running: #{cmd}"
    puts `#{cmd}`
    Resque.enqueue(Jobs::ImageToBytes, output_filename, printer_id)
  end
end
    