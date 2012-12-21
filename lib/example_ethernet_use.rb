#!/usr/bin/env ruby
require 'rubygems'
require 'ethernet' #'scratchpad'

if ARGV.length < 4
  print <<END_USAGE
Usage: #{$0} net_interface ether_type dest_mac data
  net_interface: name of the Ethernet interface, e.g. eth0
  ether_type: packet type for the Ethernet II frame, in hex (2 bytes)
  dest_mac: destination MAC for the ping packets, in hex (6 bytes)
  data: ping packet data, in hex (0-padded to 64 bytes)
END_USAGE
  exit 1
end

interface = ARGV[0]
ether_type = [ARGV[1]].pack('H*').unpack('n').first
dest_mac = ARGV[2]
data = [ARGV[3]].pack('H*')

#client = Scratchpad::Ethernet::PingClient.new interface, ether_type, dest_mac
client = Ethernet::PingClient.new interface, ether_type, dest_mac

loop do
  print "Pinging #{dest_mac}... "
  STDOUT.flush
  puts client.ping(data) ? "OK" : "Failed"
  STDOUT.flush
  sleep 1
end