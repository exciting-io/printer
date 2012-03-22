require "id_generator"
require "content_store"

class Jobs::PrepareContent
  def self.queue
    :wee_printer_prepare_content
  end

  def self.perform(printer_id, content)
    url = ContentStore.write_html_content(content)
    Resque.enqueue(Jobs::PreparePage, printer_id, url)
  end
end