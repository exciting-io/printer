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

  get "/test" do
    "#" * rand(10000)
  end

  get "/:printer_id" do
    image_job = Resque.reserve(Jobs::Print.queue(params['printer_id']))
    if image_job
      klass = Resque::Job.constantize(image_job.payload['class'])
      klass.data_for_printer(*image_job.payload['args'])
    end
  end
end