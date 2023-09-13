require "printer/backend_server/base"
require "printer/remote_printer"
require "printer/printer_ip_lookup"

class Printer::BackendServer::Polling < Printer::BackendServer::Base
  get "/:printer_id" do
    printer = Printer::RemotePrinter.find(params["printer_id"])
    printer.update(remote_printer_params(params))
    Printer::PrinterIPLookup.update(printer, request.ip)
    headers "Content-Type" => env["HTTP_ACCEPT"]
    data = printer.data_to_print
    if data
      headers "X-Print-ID" => data["print_id"]
      data["data"]
    end
  end

  private

  def remote_printer_params(params)
    type = if env["HTTP_ACCEPT"]
      if env["HTTP_ACCEPT"].include?("application/vnd.exciting.printer")
        env["HTTP_ACCEPT"].split("application/vnd.exciting.printer.").last
      elsif env["HTTP_ACCEPT"].include?("application/vnd.freerange.printer")
        env["HTTP_ACCEPT"].split("application/vnd.freerange.printer.").last
      end
    end
    version = env["HTTP_X_PRINTER_VERSION"] || "Unknown"
    {type: type, ip: request.ip, version: version}
  end
end
