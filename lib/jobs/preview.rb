require "preview"

class Jobs::Preview
  def self.queue
    :printer_preview
  end

  def self.perform(preview_id, url)
    output_filename = "public/previews/#{preview_id}.png"
    save_url_to_path(url, output_filename)
    ::Preview.store(preview_id, url, output_filename)
  end

  def self.save_url_to_path(url, path)
    cmd = "phantomjs rasterise.js #{url} #{path}"
    `#{cmd}`
  end
end
