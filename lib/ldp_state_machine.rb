class LDPStateMachine
  attr_reader :state

  def initialize(mailbox)
    @state = :idle
    @mailbox = mailbox
    @neighbor = {}
  end

  def event(event_name)
    if @state == :idle && event_name == :manual_start_passive
      @state = :active
    end
  end

  def message(ldp_message)
    case @state
    when :active
      handle_active_message(ldp_message)
    when :open_confirm
      handle_open_confirm_message(ldp_message)
    when :established
      handle_established_message(ldp_message)
    end
  end

  private

  def handle_active_message(ldp_message)
    if ldp_message.message_type == LDPMessageOpen::MESSAGE_CODE
      reply_to_open_message(ldp_message)

      send_keepalive_message

      @state = :open_confirm
    end
  end

  def reply_to_open_message(ldp_open_message)
    @mailbox.send_message(LDPMessageOpen.new(4, 65002, 0, [10, 0, 0, 2].pack('c4'), []))
  end

  def send_keepalive_message
    @mailbox.send_message(LDPMessageKeepalive.new)
  end

  def handle_open_confirm_message(ldp_message)
    if ldp_message.message_type == LDPMessageKeepalive::MESSAGE_CODE
      @state = :established
    end
  end

  def handle_established_message(ldp_message)
    puts "Message received"
    puts ldp_message.to_s
  end
end
