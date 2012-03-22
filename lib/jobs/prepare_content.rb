require "id_generator"

class Jobs::PrepareContent
  def self.queue
    :wee_printer_prepare_content
  end

  def self.perform(printer_id, content)
    path = "temp_content/#{IdGenerator.random_id}.html"
    File.open(File.expand_path("../../../public/#{path}", __FILE__), "w") do |f|
      f.write(%{<!doctype html><html class="no-js" lang="en">#{content}</html>})
    end
    url = "http://localhost:5678/#{path}"
    Resque.enqueue(Jobs::PreparePage, printer_id, url)
  end
end