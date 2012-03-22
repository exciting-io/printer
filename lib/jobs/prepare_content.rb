require "id_generator"

class Jobs::PrepareContent
  extend Jobs::Content

  def self.queue
    :wee_printer_prepare_content
  end

  def self.perform(printer_id, content)
    url = write_html_content(content)
    Resque.enqueue(Jobs::PreparePage, printer_id, url)
  end
end