require "jobs/image_to_bytes"

class Jobs::PreparePage
  def self.queue
    :wee_printer_prepare_page
  end

  def self.perform(printer_id, url)
    output_filename = "tmp/test.png"
    save_url_to_path(url, output_filename)
    Resque.enqueue(Jobs::ImageToBytes, output_filename, printer_id)
  end

  def self.save_url_to_path(url, path)
    cmd = "phantomjs rasterise.js #{url} #{path}"
    `#{cmd}`
  end
end
    