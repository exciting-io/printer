class Print
  attr_reader :id, :width, :height, :pixels

  def initialize(attributes)
    @id = attributes["id"]
    @width = attributes["width"]
    @height = attributes["height"]
    @pixels = attributes["pixels"]
  end
end