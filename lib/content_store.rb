require "id_generator"

module ContentStore
  def self.write_html_content(content, unique_id=IdGenerator.random_id)
    path = "temp_content/#{unique_id}.html"
    File.open(File.expand_path("../../public/#{path}", __FILE__), "w") do |f|
      f.write(%{<!doctype html><html class="no-js" lang="en">#{content}</html>})
    end
    "http://localhost:5678/#{path}"
  end
end