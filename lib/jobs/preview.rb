require "jobs/image_to_bytes"

class Jobs::Preview
  def self.queue
    :wee_printer_preview
  end

  def self.perform(preview_id, url)
    output_filename = "public/previews/#{preview_id}.png"
    cmd = "phantomjs rasterise.js #{url} #{output_filename}"
    `#{cmd}`
    Resque.enqueue_to(Jobs::PreviewReady.queue(preview_id), preview_id, output_filename.gsub(/^public/, ''))
  end
end
