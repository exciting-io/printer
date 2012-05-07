# encoding: utf-8

require "test_helper"
require "font_listing"

describe FontListing do
  it "calls gets the full system font names" do
    FontListing.expects(:`).with("fc-list : fullname")
    FontListing.system_font_list
  end

  describe "instances" do
    before do
      font_listing = <<-EOS

  :fullname=Georgia
  :fullname=DejaVu Sans Bold
  :fullname=Arial
  :fullname=Courier New
  :fullname=DejaVu Serif Bold
  :fullname=Trebuchet MS Bold Italic,Trebuchet MS Negreta cursiva,Trebuchet MS tučné kurzíva
  EOS
      FontListing.stubs(:system_font_list).returns(font_listing)
    end

    it "returns all font styles" do
      fonts = []
      FontListing.new.each { |f| fonts << f }
      fonts.must_equal ["Arial", 
                        "Courier New",
                        "DejaVu Sans Bold",
                        "DejaVu Serif Bold",
                        "Georgia",
                        "Trebuchet MS Bold Italic"]
    end
  end
end