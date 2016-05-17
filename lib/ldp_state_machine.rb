class LDPStateMachine
  attr_reader :state

  def initialize(mailbox)
    @state = :non_existent
    @mailbox = mailbox
    @neighbor = {}
  end

  def event(event_name)
    if @state == :non_existent && event_name == :tcp_connection_confirmed
      @state = :initialised
    end
  end

  def message(ldp_message)
    case @state
    when :initialised
      handle_initialised_message(ldp_message)
    when :openrec
      handle_openrec_message(ldp_message)
    end
  end

  private

  def handle_initialised_message(ldp_message)
    if ldp_message.message_type == LDPMessageInitialization::MESSAGE_CODE
      reply_to_initialise_message(ldp_message)

      send_keepalive_message

      @state = :openrec
    end
  end

  def reply_to_initialise_message(ldp_initialise_message)
    @mailbox.send_message(LDPMessageInitialization.new(nil, nil))
  end

  def send_keepalive_message
    @mailbox.send_message(LDPMessageKeepalive.new(nil, nil))
  end

  def handle_openrec_message(ldp_message)
    if ldp_message.message_type == LDPMessageKeepalive::MESSAGE_CODE
      @state = :operational
    end
  end
end
