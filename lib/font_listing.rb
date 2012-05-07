#:encoding: utf-8

class FontListing
  def fonts
    fonts = self.class.system_font_list.strip.split("\n").map do |f|
      f.split("=")[1].split(",").first
    end.uniq.sort
  end

  def each
    fonts.each { |f| yield f }
  end

  def pangram
    [
      "The five boxing wizards jump quickly",
      "A very bad quack might jinx zippy fowls.",
      "The quick brown fox jumps over the lazy dog.",
      "Sex prof gives back no quiz with mild joy.",
      "Blowzy red vixens fight for a quick jump.",
      "A wizard's job is to vex chumps quickly in fog.",
      "Woven silk pyjamas exchanged for blue quartz."
    ].sample
  end

  private

  def self.system_font_list
    `fc-list : fullname`
  end
end