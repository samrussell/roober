#!/bin/env ruby

require 'socket'
require 'ipaddr'
require './lib/io_slicer'
require './lib/mailbox'
require './lib/ldp_pdu'

socket = UDPSocket.new
ip_mreq = IPAddr.new("224.0.0.2").hton + IPAddr.new("10.10.10.1").hton
socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip_mreq)
socket.bind(Socket::INADDR_ANY, 646)

loop do
  mesg, sender_info = socket.recvfrom(1500)
  sender_ip = sender_info[3]
  puts "received message from #{sender_ip}"
  pdu = LDPPDU.build_from_packet(mesg)
  puts pdu.inspect

  #mailbox = Mailbox.new(client)
  #bgp_state_machine = BGPStateMachine.new(mailbox)
  #bgp_state_machine.event(:manual_start_passive)
  #bgp_message_slicer = IOSlicer.new(client, 10000000000, BGPMessagePacked)

  #bgp_message_slicer.each do |packed_bgp_message|
  #  bgp_message = BGPMessage.build_from_packet(packed_bgp_message)
  #  puts "message class: #{bgp_message.class}"
  #  puts "Forwarding message type #{bgp_message.message_type}"
  #  bgp_state_machine.message(bgp_message)
  #end
end
