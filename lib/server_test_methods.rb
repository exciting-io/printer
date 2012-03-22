module ServerTestMethods
  def self.included(base)
    base.get "/test/fixed/:length" do
      "#" * params['length'].to_i
    end

    base.get "/test/between/:min/:max" do
      min = params['min'].to_i
      max = params['max'].to_i
      length = rand(max-min) + min
      "#" * length
    end

    base.get "/test/maybe" do
      if rand(10) > 7
        "#" * (rand(100000) + 20000)
      end
    end
  end
end