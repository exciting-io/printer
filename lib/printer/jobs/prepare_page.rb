require "printer/configuration"
require "printer/jobs/image_to_bits"
require "printer/id_generator"
require "printer/preview"
require "timeout"
require "shellwords"

class Printer::Jobs::PreparePage
  def self.queue
    :printer_prepare_page
  end

  def self.perform(url, width, id, kind, print_id)
    FileUtils.mkdir_p("tmp/renders")
    case kind
    when "print"
      output_filename = "tmp/renders/#{print_id}.png"
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
      Resque.enqueue(Printer::Jobs::ImageToBits, output_filename, id, print_id)
    when "preview"
      Printer::Preview.store(id, url, result_data)
    end
  end

  def self.save_url_to_path(url, width, path)
    cmd = "phantomjs --ignore-ssl-errors=true rasterise.js #{url.shellescape} #{width} #{path}"
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
