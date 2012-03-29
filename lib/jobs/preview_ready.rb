class Jobs::PreviewReady
  class << self
    def queue(preview_id)
      "printer_preview_#{preview_id}"
    end
  end
end
