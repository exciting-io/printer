require "preview"

class Jobs::Preview
  def self.queue
    :printer_preview
  end

  def self.perform(preview_id, url, width)
    output_filename = "public/previews/#{preview_id}.png"
    result = save_url_to_path(url, width, output_filename)
    result_data = if result[:status] == 0
      {image_path: output_filename}
    else
      {error: result[:error]}
    end
    ::Preview.store(preview_id, url, result_data)
  end

  def self.save_url_to_path(url, width, path)
    cmd = "phantomjs rasterise.js #{url} #{width} #{path}"
    run(cmd)
  end

  def self.run(cmd)
    output = `#{cmd}`
    {status: $?, error: output}
  end
end
