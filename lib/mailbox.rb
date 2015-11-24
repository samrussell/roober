class Mailbox
  def initialize(socket)
    @socket = socket
  end

  def send_message(message)
    puts "Sending message type #{message.message_type}"
    packed_message = message.pack
    puts "Message is #{packed_message.unpack('H*')}"
    @socket.write(packed_message)
  end
end
