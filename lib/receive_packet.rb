#! ruby -Ku
# how to run
# sudo ruby receive_packet.rb en0 0800
#

require './ethernet'

class Receiver_LLPacket
	include Ethernet

	def initialize(eth_device, ether_type)
		ether_type = [ether_type].pack('H*').unpack('n').first
		puts ether_type
		@socket = Ethernet.raw_socket(eth_device, ether_type)
		#puts socket.show_queue
	end

	def recv_packet(buffer_size=8172)
		buffer = @socket.recv(8172)
		puts buffer
	end

end
puts 'made socket'
RLL = Receiver_LLPacket.new ARGV[0], ARGV[1]
loop_i = 0
loop do 
	RLL.recv_packet(10000)
	loop_i += 1
	p ("loop回数は，#{loop_i}　回です")
end