require "recap/ruby"

server "printer.gofreerange.com", :app
set :application, "printer"

set :repository,  "git@github.com:freerange/printer.git"
set :branch, "master"

namespace :foreman do
  task :restart do
    puts "Restart the server manually for now."
  end
end

namespace :fonts do
  task :preview do
    as_app "cd #{deploy_to} && phantomjs rasterise.js http://printer.gofreerange.com/font-test 384 #{deploy_to}/public/fonts.png"
  end
end