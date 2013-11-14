require "printer/backend_server/base"

class Printer::BackendServer::Debugging < Printer::BackendServer::Base
  get "/fixed/:length" do
    "#" * params['length'].to_i
  end

  get "/between/:min/:max" do
    min = params['min'].to_i
    max = params['max'].to_i
    length = rand(max-min) + min
    "#" * length
  end

  get "/maybe" do
    if rand(10) > 7
      "#" * (rand(100000) + 20000)
    end
  end
end
