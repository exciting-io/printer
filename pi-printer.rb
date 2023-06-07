#!/usr/bin/env ruby

require 'securerandom'
require 'net/http'
require 'serialport'
require 'pi_piper'

class PiPrinter
  POLLING_DELAY = 10 # seconds
  ID_PATH = "id.txt"
  SERVER = "printer.exciting.io" # change this if connecting to your own server
  PRINTER_TYPE = "A2-raw"
  VERSION = "1.0.0"

  def initialize(serial_port: "/dev/ttyAMA0")
    debug "Starting printer"
    reset_leds
    @all_leds.map(&:on)
    @serial_port = serial_port
    generate_id unless ids.any?
    reset_download
    sleep(1)
    @all_leds.map(&:off)
  end

  def run
    debug "Printer IDs: #{ids.inspect}"
    ids.cycle do |id|
      if download_waiting?
        if button_pressed?
          print_data
        end
      else
        check_for_download(id)
        sleep(POLLING_DELAY) unless download_waiting?
      end
    end
  end

  private

  def ids
    @ids ||= File.exist?(ID_PATH) && File.readlines(ID_PATH).map(&:strip)
  end

  def generate_id
    @ids = [SecureRandom.hex(8)]
    File.open(ID_PATH, "w") { |f| f.puts @ids.join("\n") }
  end

  def check_for_download(id)
    @activity_led.on
    debug "Checking for download on #{id}"
    uri = URI("http://#{SERVER}/printer/#{id}")
    req = Net::HTTP::Get.new(uri)

    Net::HTTP.start(uri.host, uri.port) do |http|
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = "application/vnd.exciting.printer.#{PRINTER_TYPE}"
      request['X-Printer-Version'] = VERSION

      @data = StringIO.new

      http.request(request) do |response|
        response.read_body do |chunk|
          @data.write(chunk)
        end
      end
      @activity_led.off
    end

    @data.rewind
    @download = @data.read

    if @download.length > 0
      debug "Downloaded #{@download.length} bytes; saving"
      File.open('last-print.data', 'w') { |f| f.write @download }
      @success_led.on
    end
  rescue => e
    @activity_led.off
    flash(@error_led, 5)
  end

  def download_waiting?
    !@download.empty?
  end

  def button_pressed?
    true # hard coded until GPIO integration of buttons
  end

  def print_data
    # stream data over serial connection
    debug "Printing #{@download.bytes.length} bytes to printer"
    serial.write(@download)
    reset_download
    @success_led.off
  end

  def reset_download
    @download = ''
  end

  def reset_leds
    @error_led, @activity_led, @success_led = [22,23,24].map do |pin|
      File.open("/sys/class/gpio/unexport", "w") { |f| f.write(pin) } rescue nil
      PiPiper::Pin.new(pin: pin, direction: :out)
    end
    @all_leds = [@error_led, @activity_led, @success_led]
  end

  def serial
    @serial ||= begin
      data_bits, stop_bits, baud = 8, 1, 19200
      parity = SerialPort::NONE
      serial = SerialPort.new(@serial_port, 19200, data_bits, stop_bits, parity)
      serial.sync = true
      serial
    end
  end

  def debug(message)
    STDOUT.puts "#{Time.now}: #{message}"
    STDOUT.flush
  end

  def flash(led, times)
    times.times do
      led.on
      sleep(0.3)
      led.off
      sleep(0.3)
    end
    sleep(1)
  end
end


if __FILE__ == $0
  loop do
    begin
      PiPrinter.new.run
    rescue => e
      puts "Exception while running: #{e}"
      puts e.backtrace.join("\n")
    end
  end
end
