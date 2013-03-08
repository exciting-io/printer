class Printer::BackendServer::EncodedStatusHeaderMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    headers.merge!("X-Printer-Encoded-Status" => encoded_status(status, headers))
    [status, headers, body]
  end

  private

  def encoded_status(status, headers)
    [status, headers["Content-length"], encoded_presence(headers["X-Printer-PrintImmediately"])].compact.join("|")
  end

  def encoded_presence(header)
    header ? 1 : 0
  end
end
