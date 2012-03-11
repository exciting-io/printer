require "base64"

class Jobs::Print
  class << self
    def queue(printer_id)
      "wee_printer_#{printer_id}"
    end

    def data_for_printer(encoded_data)
      Base64.decode64(encoded_data)
    end
  end
end
