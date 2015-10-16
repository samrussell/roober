class BGPMessageError < StandardError
  attr_reader :suberror

  def initialize(suberror)
    @suberror = suberror
  end
end

class BGPMessage
  @@subclasses = { }
  # extract word in big endian: substr.unpack('n')[0]
  def self.build_from_packet(raw_packet_data)
    marker, length, message_type = raw_packet_data.unpack('A16S>C')
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
  MINIMUM_PACKET_LENGTH = 29

  register_subclass 1

  def self.build_from_packet(raw_packet_data)
    marker, packet_length, message_type, bgp_version, sender_as,
      hold_time, sender_id, optional_parameters_length,
      optional_parameters = raw_packet_data.unpack('a16' +
        'S>' + 'C' + 'C' + 'S>' + 'S>' + 'a4' + 'C' + 'a*')
    if packet_length < MINIMUM_PACKET_LENGTH
      raise BGPMessageError.new(:bgp_open_bad_length), 'packet length is too short'
    elsif optional_parameters_length != packet_length - MINIMUM_PACKET_LENGTH
      raise BGPMessageError.new(:bgp_open_bad_optional_parameters_length), 'optional parameters length is off'
    elsif bgp_version != 4
      raise BGPMessageError.new(:bgp_open_bad_version), 'BGP version must be 4'
    elsif !( hold_time == 0 || hold_time >= 3)
      raise BGPMessageError.new(:bgp_open_bad_hold_time), 'Hold time must be 0 or at least 3 seconds'
    else
      new
    end
  end
end

class BGPMessageKeepalive < BGPMessage
  register_subclass 4

  def self.build_from_packet(raw_packet_data)
    new
  end
end
