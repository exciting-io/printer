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
    FileUtils.mkdir_p(File.dirname(path))
    chrome_url = ENV['CHROME_URL'] + "/screenshot"
    pdf_options = {
      url: url,
      viewport: {
        width: width
      },
      options: {
        type: 'png'
      }
    }
    cmd = ['curl', '-X POST', chrome_url, "-H 'Cache-Control: no-cache'", "-H 'Content-Type: application/json'", "-d '#{MultiJson.encode(pdf_options)}'", "-o '#{path}'"].join(' ')
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
