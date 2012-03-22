class Jobs::PreviewContent
  extend Jobs::Content

  def self.queue
    :wee_printer_preview_content
  end

  def self.perform(preview_id, content)
    url = write_html_content(content, preview_id)
    Resque.enqueue(Jobs::Preview, preview_id, url)
  end
end