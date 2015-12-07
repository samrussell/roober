#!/bin/env ruby

require 'socket'
require './lib/io_slicer'
require './lib/mailbox'
require './lib/bgp_state_machine'
require './lib/bgp_message'

server = TCPServer.new('10.0.0.2', 179)

loop do
  client = server.accept
  puts "got connection"
  mailbox = Mailbox.new(client)
  bgp_state_machine = BGPStateMachine.new(mailbox)
  bgp_state_machine.event(:manual_start_passive)
  bgp_message_slicer = IOSlicer.new(client, 10000000000, BGPMessagePacked)

  bgp_message_slicer.each do |packed_bgp_message|
    bgp_message = BGPMessage.build_from_packet(packed_bgp_message)
    puts "message class: #{bgp_message.class}"
    puts "Forwarding message type #{bgp_message.message_type}"
    bgp_state_machine.message(bgp_message)
  end
end
