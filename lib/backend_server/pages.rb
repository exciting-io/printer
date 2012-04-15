require "backend_server/base"

class BackendServer::Pages < BackendServer::Base
  get("/") { erb :index }
end
