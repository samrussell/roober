require './lib/abstract_slice'

class LDPMessagePacked < AbstractSlice
  OFFSET_OF_LENGTH_FIELD = 2
  SIZE_OF_LENGTH_FIELD = 2
  BODY_LENGTH_DIFFERENCE = 0
  LENGTH_FIELD_UNPACK_STRING = 'S>'

  protected

  def initial_length
    OFFSET_OF_LENGTH_FIELD + SIZE_OF_LENGTH_FIELD
  end

  def remainder_length
    @initial.byteslice(OFFSET_OF_LENGTH_FIELD, SIZE_OF_LENGTH_FIELD).unpack(LENGTH_FIELD_UNPACK_STRING).first + BODY_LENGTH_DIFFERENCE
  end
end

class LDPMessageError < StandardError
  attr_reader :suberror

  def initialize(suberror)
    @suberror = suberror
  end
end

class LDPMessage
  @@subclasses = { }

  UNPACK_STRING = 'A16S>C'

  def message_type
    self.class::MESSAGE_CODE
  end

  def self.build_from_packet(raw_packet_data)
    marker, length, message_type = raw_packet_data.unpack(UNPACK_STRING)
    check_header_is_valid(raw_packet_data)
    @@subclasses[message_type].build_from_packet(raw_packet_data)
  end

  def pack
    raise MethodNotImplementedError
  end

  private

  def self.check_header_is_valid(raw_packet_data)
    #marker, length, message_type = raw_packet_data.unpack('A16S>C')
    #raise ArgumentError, 'Marker is not all 0xFF' unless is_marker_all_0xff?(marker)
  end

  def self.register_subclass message_type_number
    @@subclasses[message_type_number] = self
  end
end

class LDPMessageKeepalive < LDPMessage
  MESSAGE_CODE = 4
  UNPACK_STRING = 'a16S>C'

  register_subclass MESSAGE_CODE

  def self.build_from_packet(raw_packet_data)
    new
  end

  def pack
    marker = 16.times.map {0xFF.chr}.join
    #TODO magic number!
    packet_length = 19
    [marker, packet_length, message_type].pack(UNPACK_STRING)
  end
end
