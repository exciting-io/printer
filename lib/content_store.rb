require "id_generator"
require "fileutils"

module ContentStore
  class << self
    attr_accessor :content_directory

    def write_html_content(content, unique_id=IdGenerator.random_id)
      FileUtils.mkdir_p(File.join(ContentStore.content_directory, "temp_content"))
      public_path = File.join("temp_content", "#{unique_id}.html")
      File.open(File.join(content_directory, public_path), "w") do |f|
        f.write(%{<!doctype html><html class="no-js" lang="en">#{content}</html>})
      end
      "http://localhost:#{ENV["PORT"]}/#{public_path}"
    end
  end

  self.content_directory ||= File.expand_path("../../public", __FILE__)
end