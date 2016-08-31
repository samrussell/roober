require './lib/ldp_pdu'

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
      messages = [
        generate_reply_to_initialise_message(ldp_message),
        generate_keepalive_message
      ]

      # TODO don't hardcode ips etc
      pdu = LDPPDU.new(1, 0x0a010101, 0, messages)

      @mailbox.send_message(pdu)

      @state = :openrec
    end
  end

  def generate_reply_to_initialise_message(ldp_initialise_message)
    initialization_data = "\x05\x00\x00\x0e\x00\x01\x00\xb4\x00\x00\x10\x00\x0a\x02\x02\x02\x00\x00"
    LDPMessageInitialization.new(ldp_initialise_message.message_id, initialization_data)
  end

  def generate_keepalive_message
    LDPMessageKeepalive.new(1, "")
  end

  def handle_openrec_message(ldp_message)
    if ldp_message.message_type == LDPMessageKeepalive::MESSAGE_CODE
      @state = :operational
    end
  end
end
