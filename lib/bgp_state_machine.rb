class BGPStateMachine
  attr_reader :state

  def initialize
    @state = :idle
  end

  def event(event_name)
    if @state == :idle && event_name == :manual_start
      @state = :connect
    end
  end
end
