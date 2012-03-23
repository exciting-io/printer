require "test_helper"
require "content_store"

describe ContentStore do
  it "wraps the given content in html tags" do
    ContentStore.write_html_content("content", "id")
    expected_html = %{<!doctype html><html class="no-js" lang="en">content</html>}
    file_path = File.join(ContentStore.content_directory, "temp_content/id.html")
    File.read(file_path).must_equal expected_html
  end

  it "stores the file using the id given" do
    ContentStore.write_html_content("content", "other-id")
    File.exists?(File.join(ContentStore.content_directory, "temp_content/other-id.html")).must_equal true
  end

  it "uses a default random id if no ID was given" do
    IdGenerator.stubs(:random_id).returns("default-id")
    ContentStore.write_html_content("content")
    File.exists?(File.join(ContentStore.content_directory, "temp_content/default-id.html")).must_equal true
  end
end