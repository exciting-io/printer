require "printer/backend_server/base"
require "printer/remote_printer"
require "printer/printer_ip_lookup"

class Printer::BackendServer::Polling < Printer::BackendServer::Base
  get "/:printer_id" do
    printer = Printer::RemotePrinter.find(params["printer_id"])
    printer.update(remote_printer_params(params))
    Printer::PrinterIPLookup.update(printer, request.ip)
    printer.data_to_print
  end

  private

  def remote_printer_params(params)
    type = env["HTTP_ACCEPT"] ? env["HTTP_ACCEPT"].split("application/vnd.freerange.printer.").last : nil
    version = env["HTTP_X_PRINTER_VERSION"] || "Unknown"
    {type: type, ip: request.ip, version: version}
  end
end
