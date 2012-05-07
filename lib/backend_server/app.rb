module BackendServer
  App = Rack::Builder.new do
    map("/printer")    { run BackendServer::Polling  }
    map("/preview")    { run BackendServer::Preview  }
    map("/print")      { run BackendServer::Print    }
    map("/my-printer") { run BackendServer::Settings }
    map("/archive")    { run BackendServer::Archive  }
    map("/")           { run BackendServer::Pages    }
  end
end