class Jobs::PreviewReady
  class << self
    def queue(preview_id)
      "wee_printer_preview_#{preview_id}"
    end
  end
end
