require "printer/backend_server/base"
require "printer/font_listing"

class Printer::BackendServer::Pages < Printer::BackendServer::Base
  get("/") { erb :index }
  get("/font-test") do
    @fonts = Printer::FontListing.new
    erb :font_test, layout: :print_layout
  end
end
