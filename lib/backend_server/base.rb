require "sinatra"
require "sinatra/base"
require "multi_json"

class BackendServer::Base < Sinatra::Base
  set :views, settings.root + '/../../views'
  set :public_folder, settings.root + '/../../public'

  set :protection, :except => :json_csrf

  private

  def absolute_url_for_path(path)
    request.scheme + "://" + request.host_with_port + path
  end

  def respond_with_json(data)
    headers "Access-Control-Allow-Origin" => "*"
    content_type :json
    MultiJson.encode(data)
  end

  def print_url(printer)
    absolute_url_for_path("/print/#{printer.id}")
  end
end