require "rubygems"
require "bundler/setup"
require "sinatra"
require 'sinatra/base'
require "resque"

$LOAD_PATH.unshift "lib"
require "jobs"
require "sudoku"

class WeePrinterServer < Sinatra::Base
  get "/preview" do
    @sudoku_data = random_sudoku
    erb :index
  end

  get "/print_from_page/:printer_id" do
    Resque.enqueue(Jobs::PreparePage, params['printer_id'], env['HTTP_REFERER'])
    redirect env['HTTP_REFERER']
  end

  get "/test/fixed/:length" do
    "#" * params['length'].to_i
  end

  get "/test/between/:min/:max" do
    min = params['min'].to_i
    max = params['max'].to_i
    length = rand(max-min) + min
    "#" * length
  end

  get "/test/maybe" do
    if rand(10) > 7
      "#" * (rand(100000) + 20000)
    end
  end

  get "/:printer_id" do
    image_job = Resque.reserve(Jobs::Print.queue(params['printer_id']))
    if image_job
      klass = Resque::Job.constantize(image_job.payload['class'])
      klass.data_for_printer(*image_job.payload['args'])
    end
  end
end