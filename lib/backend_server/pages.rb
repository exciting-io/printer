require "backend_server/base"
require "font_listing"

class BackendServer::Pages < BackendServer::Base
  get("/") { erb :index }
  get("/font-test") do
    @fonts = FontListing.new
    erb :font_test, layout: :print_layout
  end
end
