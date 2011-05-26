# Documentation here.
module Ethernet
end

require 'ethernet/raw_socket.rb'
require 'ethernet/socket_wrapper.rb'

# TODO(pwnall): move to separate gem
require 'ethernet/ping.rb' # This is to get ethernet_ping working :P
