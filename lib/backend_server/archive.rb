require "backend_server/base"
require "remote_printer"

class BackendServer::Archive < BackendServer::Base
  get "/:printer_id/image/:image_id.png" do
    printer = RemotePrinter.find(params[:printer_id])
    print = printer.find_print(params[:image_id])
    image = print.to_image
    image.format = "PNG"
    [200, {"Content-Type" => "image/png"}, image.to_blob]
  end

  get "/:printer_id" do
    @printer = RemotePrinter.find(params[:printer_id])
    @prints = @printer.all_prints
    erb :archive
  end
end