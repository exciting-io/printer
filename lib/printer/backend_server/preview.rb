require "printer/backend_server/base"
require "resque"
require "printer/jobs"
require "printer/id_generator"
require "printer/content_store"
require "printer/preview"

class Printer::BackendServer::Preview < Printer::BackendServer::Base
  get "/show/:preview_id" do
    @preview = Printer::Preview.find(params['preview_id'])
    erb :preview
  end

  get "/pending/:preview_id" do
    preview = Printer::Preview.find(params['preview_id'])
    if preview
      redirect to("/show/#{params['preview_id']}")
    else
      erb :preview_pending
    end
  end

  get "/" do
    process
  end

  post "/" do
    process
  end

  private

  def process
    if url_to_process
      queue_preview(url_to_process, width)
    elsif content_to_process
      queue_preview_from_content(content_to_process, width)
    else
      erb :api_help
    end
  end

  def content_to_process
    params['content']
  end

  def url_to_process
    params['url']
  end

  def width
    params['width'] || '384'
  end

  def queue_preview(url, width)
    preview_id = Printer::IdGenerator.random_id
    Resque.enqueue(Printer::Jobs::PreparePage, url, width, preview_id, "preview")
    redirect to("/pending/#{preview_id}")
  end

  def queue_preview_from_content(content, width)
    preview_id = Printer::IdGenerator.random_id
    path = Printer::ContentStore.write_html_content(content, preview_id)
    Resque.enqueue(Printer::Jobs::PreparePage, absolute_url_for_path(path), width, preview_id, "preview")
    preview_pending_path = absolute_url_for_path("/preview/pending/#{preview_id}")
    if request.accept?('application/json')
      respond_with_json(location: preview_pending_path)
    else
     redirect preview_pending_path
    end
  end
end
