require "jobs/image_to_bits"
require "id_generator"

class Jobs::PreparePage
  def self.queue
    :printer_prepare_page
  end

  def self.output_id
    IdGenerator.random_id
  end

  def self.perform(printer_id, url)
    FileUtils.mkdir_p("tmp/renders")
    output_filename = "tmp/renders/#{output_id}.png"
    save_url_to_path(url, output_filename)
    Resque.enqueue(Jobs::ImageToBits, output_filename, printer_id)
  end

  def self.save_url_to_path(url, path)
    cmd = "phantomjs rasterise.js #{url} #{path}"
    `#{cmd}`
  end
end
    