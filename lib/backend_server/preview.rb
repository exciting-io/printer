require "backend_server/base"
require "resque"
require "jobs"
require "id_generator"
require "content_store"
require "preview"

class BackendServer::Preview < BackendServer::Base
  get "/show/:preview_id" do
    @preview = Preview.find(params['preview_id'])
    erb :preview
  end

  get "/pending/:preview_id" do
    preview = Preview.find(params['preview_id'])
    if preview
      redirect "/preview/show/#{params['preview_id']}"
    else
      erb :preview_pending
    end
  end

  get "/" do
    if url_to_process
      queue_preview(url_to_process, width)
    else
      erb :api_help
    end
  end

  post "/" do
    if params['content']
      queue_preview_from_content(params['content'], width)
    else
      queue_preview(url_to_process, width)
    end
  end

  private

  def url_to_process
    params['url']
  end

  def width
    params['width'] || '384'
  end

  def queue_preview(url, width)
    preview_id = IdGenerator.random_id
    Resque.enqueue(Jobs::Preview, preview_id, url, width)
    redirect "/preview/pending/#{preview_id}"
  end

  def queue_preview_from_content(content, width)
    preview_id = IdGenerator.random_id
    path = ContentStore.write_html_content(content, preview_id)
    Resque.enqueue(Jobs::Preview, preview_id, absolute_url_for_path(path), width)
    preview_pending_path = absolute_url_for_path("/preview/pending/#{preview_id}")
    if request.accept?('application/json')
      respond_with_json(location: preview_pending_path)
    else
     redirect preview_pending_path
    end
  end
end