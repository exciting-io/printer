require "test_helper"
require "printer/content_store"

describe Printer::ContentStore do
  it "wraps the given content in html tags" do
    Printer::ContentStore.write_html_content("content", "id")
    expected_html = %{<!doctype html><html class="no-js" lang="en">content</html>}
    file_path = File.join(Printer::ContentStore.content_directory, "/temp_content/id.html")
    File.read(file_path).must_equal expected_html
  end

  it "doesn't wrap the content in HTML tags if it already contains them" do
    Printer::ContentStore.write_html_content("<html>content</html>", "id")
    expected_html = %{<html>content</html>}
    file_path = File.join(Printer::ContentStore.content_directory, "/temp_content/id.html")
    File.read(file_path).must_equal expected_html
  end

  it "stores the file using the id given" do
    Printer::ContentStore.write_html_content("content", "other-id")
    File.exists?(File.join(Printer::ContentStore.content_directory, "/temp_content/other-id.html")).must_equal true
  end

  it "uses a default random id if no ID was given" do
    Printer::IdGenerator.stubs(:random_id).returns("default-id")
    Printer::ContentStore.write_html_content("content")
    File.exists?(File.join(Printer::ContentStore.content_directory, "/temp_content/default-id.html")).must_equal true
  end

  it "returns the public path for the file" do
    path = Printer::ContentStore.write_html_content("content", "id")
    path.must_equal "/temp_content/id.html"
  end
end
