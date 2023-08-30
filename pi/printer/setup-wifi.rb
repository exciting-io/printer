#!/usr/bin/env ruby

puts "Setting up wifi..."
print "SSID: "
ssid = gets.chomp
print "Password: "
password = gets.chomp

File.open(File.join(File.dirname(__FILE__), '..', "wpa_supplicant.conf"), "w") do |f|
  f.puts <<~EOF
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    country=US

    network={
      ssid="#{ssid}"
      psk="#{password}"
    }
  EOF
end
