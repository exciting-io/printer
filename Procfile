web: bundle exec unicorn -p 4567 -o 0.0.0.0
prepare_page: bundle exec rake resque:work QUEUE=wee_printer_prepare_page VERBOSE=1
image_to_bytes: bundle exec rake resque:work QUEUE=wee_printer_images VERBOSE=1
preview: bundle exec rake resque:work QUEUE=wee_printer_preview VERBOSE=1