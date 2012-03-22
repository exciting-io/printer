class Jobs::PreviewContent
  def self.queue
    :wee_printer_preview_content
  end

  def self.perform(preview_id, content)
    path = "preview_content/#{preview_id}.html"
    File.open(File.expand_path("../../../public/#{path}", __FILE__), "w") do |f|
      f.write(%{<!doctype html><html class="no-js" lang="en">#{content}</html>})
    end
    url = "http://localhost:5678/#{path}"
    Resque.enqueue(Jobs::Preview, preview_id, url)
  end
end