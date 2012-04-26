require "recap/ruby"

server "printer.gofreerange.com", :app
set :application, "printer"

set :repository,  "git@github.com:freerange/printer.git"
set :branch, "master"

namespace :foreman do
  task :restart do
    if deployed_file_changed?(procfile)
      sudo "restart #{application} || sudo start #{application}"
    else
      sudo "reload #{application} || sudo start #{application}"
    end
  end
end