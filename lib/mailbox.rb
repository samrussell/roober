class Mailbox
  def initialize(socket)
    @socket = socket
  end

  def send_message(message)
    @socket.send(message.pack)
  end
end
