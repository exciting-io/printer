require "test_helper"
require "printer/content_store"

describe Printer::ContentStore do
  let(:subject) { Printer::ContentStore }

  it "wraps the given content in html tags" do
    subject.write_html_content("content", "id")
    expected_html = %{<!doctype html><html class="no-js" lang="en">content</html>}
    file_path = File.join(subject.content_directory, "/temp_content/id.html")
    File.read(file_path).must_equal expected_html
  end

  it "doesn't wrap the content in HTML tags if it already contains them" do
    subject.write_html_content("<html>content</html>", "id")
    expected_html = %{<html>content</html>}
    file_path = File.join(subject.content_directory, "/temp_content/id.html")
    File.read(file_path).must_equal expected_html
  end

  it "stores the file using the id given" do
    subject.write_html_content("content", "other-id")
    File.exists?(File.join(subject.content_directory, "/temp_content/other-id.html")).must_equal true
  end

  it "uses a default random id if no ID was given" do
    Printer::IdGenerator.stubs(:random_id).returns("default-id")
    subject.write_html_content("content")
    File.exists?(File.join(subject.content_directory, "/temp_content/default-id.html")).must_equal true
  end

  it "returns the public path for the file" do
    path = subject.write_html_content("content", "id")
    path.must_equal "/temp_content/id.html"
  end
end
