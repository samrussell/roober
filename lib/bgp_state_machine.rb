require './lib/bgp_message'

class BGPStateMachine
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

  def message(bgp_message)
    case @state
    when :active
      handle_active_message(bgp_message)
    when :open_confirm
      handle_open_confirm_message(bgp_message)
    when :established
      handle_established_message(bgp_message)
    end
  end

  private

  def handle_active_message(bgp_message)
    if bgp_message.message_type == BGPMessageOpen::MESSAGE_CODE
      reply_to_open_message(bgp_message)

      send_keepalive_message

      @state = :open_confirm
    end
  end

  def reply_to_open_message(bgp_open_message)
    @mailbox.send_message(BGPMessageOpen.new(4, 1234, 0, 0x0a000, []))
  end

  def send_keepalive_message
    @mailbox.send_message(BGPMessageKeepalive.new)
  end

  def handle_open_confirm_message(bgp_message)
    if bgp_message.message_type == BGPMessageKeepalive::MESSAGE_CODE
      @state = :established
    end
  end

  def handle_established_message(bgp_message)
    puts "Message received"
    puts bgp_message.inspect
  end
end
