class BGPMessage
  @@subclasses = { }
  # extract word in big endian: substr.unpack('n')[0]
  def self.build_from_packet(raw_packet_data)
    message_type_number = raw_packet_data.getbyte(18)
    # TODO should do subclass.build_from_packet() instead
    @@subclasses[message_type_number].new(raw_packet_data) if is_header_valid?(raw_packet_data)
  end

  private

  def self.is_header_valid?(raw_packet_data)
    are_first_16_bytes_all_0xff?(raw_packet_data)
  end

  def self.are_first_16_bytes_all_0xff?(raw_packet_data)
    raw_packet_data[0...16] == "\xff" * 16
  end

  def self.register_subclass message_type_number
    @@subclasses[message_type_number] = self
  end
end

class BGPMessageKeepalive < BGPMessage
  register_subclass 4

  def initialize(raw_packet_data)
    @raw_packet_data = raw_packet_data
  end
end
