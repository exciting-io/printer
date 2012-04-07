web: bundle exec unicorn -p $PORT
prepare_page: bundle exec rake resque:work QUEUE=printer_prepare_page VERBOSE=1
image_to_bits: bundle exec rake resque:work QUEUE=printer_images VERBOSE=1
preview: bundle exec rake resque:work QUEUE=printer_preview VERBOSE=1