require "backend_server/base"
require "resque"
require "jobs"
require "content_store"

class BackendServer::Print < BackendServer::Base
  get "/:printer_id" do
    if url_to_process
      queue_print(params['printer_id'], url_to_process)
    else
      erb :api_help
    end
  end

  post "/:printer_id" do
    if params['content']
      queue_print_from_content(params['printer_id'], params['content'])
    else
      queue_print(params['printer_id'], url_to_process)
    end
  end

  private

  def url_to_process
    params['url']
  end

  def queue_print(printer_id, url)
    Resque.enqueue(Jobs::PreparePage, printer_id, url)
    erb :queued
  end

  def queue_print_from_content(printer_id, content)
    path = ContentStore.write_html_content(content)
    Resque.enqueue(Jobs::PreparePage, printer_id, absolute_url_for_path(path))
    if request.accept?('application/json')
      respond_with_json(response: "ok")
    else
      erb :queued
    end
  end
end