require "printer/backend_server/base"
require "printer/remote_printer"
require "printer/printer_ip_lookup"

class Printer::BackendServer::Settings < Printer::BackendServer::Base
  get "/" do
    @printers = Printer::PrinterIPLookup.find_printer(request.ip)
    erb :my_printer
  end

  get "/:printer_id" do
    @printers = [Printer::RemotePrinter.find(params[:printer_id])]
    erb :my_printer
  end

  put "/:printer_id" do
    @printer = Printer::RemotePrinter.find(params[:printer_id])
    @printer.update(params[:printer])
    redirect "/my-printer"
  end

  get "/:printer_id/test-page" do
    @printer = Printer::RemotePrinter.find(params[:printer_id])
    @print_url = print_url(@printer)
    erb :test_page, layout: :print_layout
  end
end
