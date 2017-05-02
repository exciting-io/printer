require "printer/configuration"
require "printer/jobs/image_to_bits"
require "printer/id_generator"
require "printer/preview"
require "timeout"

class Printer::Jobs::PreparePage
  def self.queue
    :printer_prepare_page
  end

  def self.output_id
    Printer::IdGenerator.random_id
  end

  def self.perform(url, width, id, kind="print")
    FileUtils.mkdir_p("tmp/renders")
    case kind
    when "print"
      output_filename = "tmp/renders/#{output_id}.png"
    when "preview"
      output_filename = "public/previews/#{id}.png"
    end
    result = save_url_to_path(url, width, output_filename)
    result_data = if result[:status] == 0
      {image_path: output_filename}
    else
      {error: result[:error]}
    end
    case kind
    when "print"
      Resque.enqueue(Printer::Jobs::ImageToBits, output_filename, id)
    when "preview"
      Printer::Preview.store(id, url, result_data)
    end
  end

  def self.save_url_to_path(url, width, path)
    cmd = "phantomjs rasterise.js #{url} #{width} #{path}"
    run(cmd)
  end

  def self.run(cmd)
    output = ''
    Timeout::timeout(15) do
      output = `#{cmd}`
    end
    {status: $?.exitstatus, error: output.strip}
  end
end
