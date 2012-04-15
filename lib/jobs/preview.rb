require "preview"

class Jobs::Preview
  def self.queue
    :printer_preview
  end

  def self.perform(preview_id, url, width)
    output_filename = "public/previews/#{preview_id}.png"
    save_url_to_path(url, width, output_filename)
    ::Preview.store(preview_id, url, output_filename)
  end

  def self.save_url_to_path(url, width, path)
    cmd = "phantomjs rasterise.js #{url} #{width} #{path}"
    `#{cmd}`
  end
end
