class BGPMessageError < StandardError
  attr_reader :suberror

  def initialize(suberror)
    @suberror = suberror
  end
end

class BGPMessage
  @@subclasses = { }

  UNPACK_STRING = 'A16S>C'

  def message_type
    MESSAGE_CODE
  end

  def self.build_from_packet(raw_packet_data)
    marker, length, message_type = raw_packet_data.unpack(UNPACK_STRING)
    check_header_is_valid(raw_packet_data)
    @@subclasses[message_type].build_from_packet(raw_packet_data)
  end

  private

  def self.check_header_is_valid(raw_packet_data)
    marker, length, message_type = raw_packet_data.unpack('A16S>C')
    raise ArgumentError, 'Marker is not all 0xFF' unless is_marker_all_0xff?(marker)
  end

  def self.is_marker_all_0xff?(marker)
    # TODO: get rid of magic number
    # TODO: make Marker class?
    marker.force_encoding('UTF-8') == "\xff" * 16
  end

  def self.register_subclass message_type_number
    @@subclasses[message_type_number] = self
  end
end

class BGPMessageOpen < BGPMessage
  ERROR_MESSAGES = {
    bgp_open_bad_length: 'packet length is too short',
    bgp_open_bad_optional_parameters_length: 'optional parameters length is off',
    bgp_open_bad_version: 'BGP version must be 4',
    bgp_open_bad_hold_time: 'Hold time must be 0 or at least 3 seconds'
  }

  MINIMUM_PACKET_LENGTH = 29
  MESSAGE_CODE = 1
  BGP_VERSION = 4
  ZERO_HOLD_TIME = 0
  MINIMUM_HOLD_TIME = 3
  UNPACK_STRING = 'a16S>CCS>S>a4Ca*'

  attr_reader :packet_length
  attr_reader :message_type
  attr_reader :bgp_version
  attr_reader :sender_as
  attr_reader :hold_time
  attr_reader :sender_id

  register_subclass MESSAGE_CODE

  def initialize(marker, packet_length, message_type,
                 bgp_version, sender_as, hold_time,
                 sender_id, optional_parameters_length,
                 optional_parameters)
    @marker = marker
    @packet_length = packet_length
    @message_type = message_type
    @bgp_version = bgp_version
    @sender_as = sender_as
    @hold_time = hold_time
    @sender_id = sender_id
    @optional_parameters_length = optional_parameters_length
    @packed_optional_parameters = optional_parameters

    validate_parameters
  end

  def optional_parameters
    @optional_parameters ||= BGPOpenOptionalParameter.build_from_packet(@packed_optional_parameters)
  end

  def self.build_from_packet(raw_packet_data)
    new(*raw_packet_data.unpack(UNPACK_STRING))
  end

  private

  def validate_parameters
    if bad_packet_length?
      raise_error(:bgp_open_bad_length)
    elsif bad_optional_parameters_length?
      raise_error(:bgp_open_bad_optional_parameters_length)
    elsif bad_version?
      raise_error(:bgp_open_bad_version)
    elsif bad_hold_time?
      raise_error(:bgp_open_bad_hold_time)
    end
  end

  def bad_packet_length?
    @packet_length < MINIMUM_PACKET_LENGTH
  end

  def bad_optional_parameters_length?
    @optional_parameters_length != @packet_length - MINIMUM_PACKET_LENGTH
  end

  def bad_version?
    @bgp_version != BGP_VERSION
  end

  def bad_hold_time?
    @hold_time != ZERO_HOLD_TIME && @hold_time < MINIMUM_HOLD_TIME
  end

  def raise_error(error)
    raise BGPMessageError.new(error), ERROR_MESSAGES[error]
  end
end

class BGPMessageKeepalive < BGPMessage
  MESSAGE_CODE = 4

  register_subclass MESSAGE_CODE

  def self.build_from_packet(raw_packet_data)
    new
  end
end
