require "printer/backend_server/base"
require "printer/remote_printer"

class Printer::BackendServer::Archive < Printer::BackendServer::Base
  get "/:printer_id/image/:image_id.png" do
    printer = Printer::RemotePrinter.find(params[:printer_id])
    print = printer.find_print(params[:image_id])
    image = print.to_image
    image.format = "PNG"
    [200, {"Content-Type" => "image/png"}, image.to_blob]
  end

  get "/:printer_id/reprint/:image_id" do
    printer = Printer::RemotePrinter.find(params[:printer_id])
    print = printer.find_print(params[:image_id])
    printer.queue_print(print)
    redirect to("#{params[:printer_id]}")
  end

  get "/:printer_id" do
    @per_page = 10
    @page = (params[:page] || 1).to_i
    @printer = Printer::RemotePrinter.find(params[:printer_id])
    @prints = @printer.all_prints(@page, @per_page)
    @total = @printer.total_prints
    erb :archive
  end
end
