require "printer/backend_server/base"
require "resque"
require "printer/jobs"
require "printer/content_store"

class Printer::BackendServer::Print < Printer::BackendServer::Base
  get "/:printer_id" do
    process
  end

  post "/:printer_id" do
    process
  end

  private

  def process
    if url_to_process
      queue_print(printer_id, url_to_process)
    elsif content_to_process
      queue_print_from_content(printer_id, content_to_process)
    else
      erb :api_help
    end
  end

  def printer_id
    params['printer_id']
  end

  def content_to_process
    params['content']
  end

  def url_to_process
    params['url']
  end

  def queue_print(printer_id, url)
    Resque.enqueue(Printer::Jobs::PreparePage, url, "384", printer_id)
    erb :queued
  end

  def queue_print_from_content(printer_id, content)
    path = Printer::ContentStore.write_html_content(content)
    Resque.enqueue(Printer::Jobs::PreparePage, absolute_url_for_path(path), "384", printer_id)
    if request.accept?('application/json')
      respond_with_json(response: "ok")
    else
      erb :queued
    end
  end
end
