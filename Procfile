web: bundle exec shotgun -p 4567
prepare_page: bundle exec rake resque:work QUEUE=wee_printer_prepare_page VERBOSE=1
image_to_bytes: bundle exec rake resque:work QUEUE=wee_printer_images VERBOSE=1 