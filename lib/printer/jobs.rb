require "printer"

module Printer::Jobs
  autoload :ImageToBits, "printer/jobs/image_to_bits"
  autoload :PreparePage, "printer/jobs/prepare_page"
end
