require "recap/recipes/ruby"

server "printer.exciting.io", :app
set :application, "printer"

set :repository,  "git@github.com:exciting-io/printer.git"
set :branch, "master"

namespace :foreman do
  task :restart do
    puts "\n\n\n\nIMPORTANT!\n\nRestart the server manually for now.\n\n\n\n"
  end
end

namespace :fonts do
  task :preview do
    as_app "cd #{deploy_to} && phantomjs --ignore-ssl-errors=true rasterise.js http://printer.exciting.io/font-test 384 #{deploy_to}/public/font-test.png"
  end
end

after "deploy:restart", "fonts:preview"
