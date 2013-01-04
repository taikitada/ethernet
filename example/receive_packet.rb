# how to run
# sudo ruby receive_packet.rb en0 0800
#
$LOAD_PATH << File.dirname(File.dirname(__FILE__))
require '../lib/ethernet'

class Receiver_LLPacket
	include Ethernet

	def initialize(eth_device, ether_type)
		ether_type = [ether_type].pack('H*').unpack('n').first
		puts ether_type
		socket = Ethernet.raw_socket(eth_device, ether_type)
		while true
			socket.recv(8172)
			socket.show_queue
			print "1"
		end
	end

	def recv_packet(buffer_size=8172)
		puts buffer_size
		puts 'recv_packet'
	end

end
puts 'made socket'
#RLL = Receiver_LLPacket.new ARGV[0], ARGV[1]
ether_type = [ARGV[1]].pack('H*').unpack('n').first
RS = Ethernet.raw_socket ARGV[0], ether_type
#RLL.recv_packet(10000)
hoge = RS.recv(8000)
count = 0
while true
	puts (hoge.unpack("H12H12"))[1]
	puts count
	count += 1
end