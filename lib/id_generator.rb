module IdGenerator
  def self.random_id
    (0...16).map { |x| rand(16).to_s(16) }.join
  end
end