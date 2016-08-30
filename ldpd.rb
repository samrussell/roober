#!/bin/env ruby

require 'socket'
require 'ipaddr'
require './lib/io_slicer'
require './lib/mailbox'
require './lib/ldp_pdu'
require './lib/ldp_message'
require './lib/ldp_parameter'
require './lib/ldp_state_machine'

# ruby multicast code taken from https://github.com/ptrv/ruby-multicast-example

HELLO_SEND_INTERVAL = 5
HELLO_HOLD_TIME = HELLO_SEND_INTERVAL * 3
Thread.abort_on_exception = true

Thread.new do
  MULTICAST_ADDR = "224.0.0.2"
  PORT= 646
  SOURCE_ADDR = "10.10.10.1"
  socket = UDPSocket.open

  begin
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_TTL, [1].pack('i'))
    socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_IF, IPAddr.new(SOURCE_ADDR).hton)

    message_id = 0

    loop do
      message_id += 1
      ip_parameter = LDPParameterIPv4Address.new(IPAddr.new("10.1.1.1").to_i)
      message = LDPMessageHello.new(message_id, 15, false, false, ip_parameter.pack)
      pdu = LDPPDU.new(1, 0x0a010101, 0, [message])
      socket.send(pdu.pack, 0, MULTICAST_ADDR, PORT)
      sleep(HELLO_SEND_INTERVAL)
    end
  ensure
    socket.close
  end
end

Thread.new do
  server = TCPServer.new("10.1.1.1", 646)

  loop do
    client = server.accept
    puts "got connection"

    mailbox = Mailbox.new(client)
    ldp_state_machine = LDPStateMachine.new(mailbox)
    ldp_state_machine.event(:tcp_connection_confirmed)
    ldp_pdu_slicer = IOSlicer.new(client, 10000000000, LDPPDUPacked)

    ldp_pdu_slicer.each do |packed_ldp_pdu|
      ldp_pdu = LDPPDU.build_from_packet(packed_ldp_pdu)
      puts ldp_pdu.inspect
      ldp_pdu.messages.each do |ldp_message|
        puts ldp_message.inspect
        ldp_state_machine.message(ldp_message)
      end
    end
  end
end


socket = UDPSocket.new
ip_mreq = IPAddr.new("224.0.0.2").hton + IPAddr.new("10.10.10.1").hton
socket.setsockopt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, ip_mreq)
socket.bind(Socket::INADDR_ANY, 646)

loop do
  # process hellos
  mesg, sender_info = socket.recvfrom(1500)
  sender_ip = sender_info[3]
  puts "received message from #{sender_ip}"
  pdu = LDPPDU.build_from_packet(mesg)
  puts pdu.inspect
end
