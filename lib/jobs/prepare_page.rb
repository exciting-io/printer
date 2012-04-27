require "jobs/image_to_bits"
require "id_generator"
require "preview"

class Jobs::PreparePage
  def self.queue
    :printer_prepare_page
  end

  def self.output_id
    IdGenerator.random_id
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
      Resque.enqueue(Jobs::ImageToBits, output_filename, id)
    when "preview"
      ::Preview.store(id, url, result_data)
    end
  end

  def self.save_url_to_path(url, width, path)
    cmd = "phantomjs rasterise.js #{url} #{width} #{path}"
    run(cmd)
  end

  def self.run(cmd)
    output = `#{cmd}`
    {status: $?.exitstatus, error: output.strip}
  end
end
    