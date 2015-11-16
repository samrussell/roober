require './lib/bgp_message'

class BGPStateMachine
  attr_reader :state

  def initialize(mailbox)
    @state = :idle
    @mailbox = mailbox
  end

  def event(event_name)
    if @state == :idle && event_name == :manual_start_passive
      @state = :active
    end
  end

  def message(bgp_message)
    if @state == :active && bgp_message.message_type == BGPMessageOpen::MESSAGE_CODE
      @mailbox.send_message(BGPMessageOpen.new(4, 1234, 0, 0x0a000, []))
      @mailbox.send_message(BGPMessageKeepalive.new)
      #@mailbox.send(BGPMessageKeepalive.new)
      @state = :open_confirm
    end
  end
end
