#!/usr/bin/env ruby

require 'securerandom'
require 'net/http'
require 'serialport'
require 'pi_piper'

class PiPrinter
  POLLING_DELAY = 10 # seconds
  ID_PATH = "/boot/printer/ids.txt"
  SERVER = "printer.exciting.io" # change this if connecting to your own server
  PRINTER_TYPE = "A2-raw"
  VERSION = "1.1.0"

  def self.test(serial_port:)
    printer = PiPrinter.new(serial_port: serial_port, debug_to_serial: true)
    printer.debug("Running printer tests")
    printer.debug("IDs: #{printer.ids}")
    printer.debug("Version: #{VERSION}")
    printer.debug("Serial port: #{serial_port}")
    printer.debug("Server: #{SERVER}")
    printer.debug("Printer type: #{PRINTER_TYPE}")
    printer.debug("Network status:")
    printer.debug(`ifconfig wlan0 | grep "inet "`.strip)
    sleep(1)

    printer.debug("Testing LEDs")
    sleep(1)
    { error: printer.error_led, activity: printer.activity_led, success: printer.success_led }.each do |type, led|
      printer.debug("Testing #{type} LED #{led.pin}")
      printer.with_led(type) do
        sleep(2)
      end
    end

    printer.debug("\n\nTests seem OK\n\n\n\n")
  end

  def self.run(serial_port:)
    loop do
      begin
        PiPrinter.new(serial_port: serial_port).run
      rescue => e
        puts "Exception while running: #{e}"
        puts e.backtrace.join("\n")
      end
    end
  end

  attr_reader :error_led, :activity_led, :success_led

  def initialize(serial_port:, debug_to_serial: false)
    @serial_port = serial_port
    @debug_to_serial = debug_to_serial

    @error_led, @activity_led, @success_led = [22,23,24].map do |pin|
      File.open("/sys/class/gpio/unexport", "w") { |f| f.write(pin) } rescue nil
      PiPiper::Pin.new(pin: pin, direction: :out)
    end
    @all_leds = [@error_led, @activity_led, @success_led]
  end

  def run
    debug "Starting printer"

    with_led(:error, :activity, :success) do
      generate_id unless ids
      reset_download
      sleep(1)
    end

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

  def with_led(*types)
    leds = types.map { |type| send("#{type}_led") }
    leds.each(&:on)
    yield
  ensure
    leds.each(&:off)
  end

  def ids
    @ids ||= File.exist?(ID_PATH) && File.readlines(ID_PATH).map(&:strip)
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
    serial.puts(message) if @debug_to_serial
  end

  private

  def generate_id
    @ids = [SecureRandom.hex(8)]
    debug "Generating new printer ID: #{@ids[0]}"
    File.open(ID_PATH, "w") { |f| f.puts @ids.join("\n") }
  end

  def check_for_download(id)
    with_led(:activity) do
      debug "Checking for download on #{id}"
      url = URI("https://#{SERVER}/printer/#{id}")

      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == 'https'

      path = url.path.empty? ? '/' : url.path

      request = Net::HTTP::Get.new(path)
      request['Accept'] = "application/vnd.exciting.printer.#{PRINTER_TYPE}"
      request['X-Printer-Version'] = VERSION

      @data = StringIO.new

      http.request(request) do |response|
        if response.code == '200'
          response.read_body do |chunk|
            @data.write(chunk)
          end
        else
          debug "Request failed with response code: #{response.code}"
        end
      end
    end

    @data.rewind
    @download = @data.read

    if @download.length > 0
      debug "Downloaded #{@download.length} bytes; saving"
      File.open('last-print.data', 'w') { |f| f.write @download }
      @success_led.on
    end
  rescue => e
    File.open('last-print.error', 'w') { |f| f.puts Time.now; f.puts e.message; f.puts e.backtrace.join("\n") }
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
  serial_port = "/dev/serial0"

  files = Dir['/boot/printer/*.txt'].map { |p| File.basename(p).downcase }
  has_test_file = files.include?('test.txt')

  case ARGV[0]
  when 'test'
    PiPrinter.test(serial_port: serial_port)
  else
    if has_test_file
      PiPrinter.test(serial_port: serial_port)
    end
    PiPrinter.run(serial_port: serial_port)
  end
end
