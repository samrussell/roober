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

  UNPACK_STRING = 'S>'

  def message_type
    self.class::MESSAGE_CODE
  end

  def self.build_from_packet(raw_packet_data)
    message_type, = raw_packet_data.unpack(UNPACK_STRING)
    check_header_is_valid(raw_packet_data)
    @@subclasses[message_type].build_from_packet(raw_packet_data)
  end

  def pack
    raise MethodNotImplementedError
  end

  private

  def self.check_header_is_valid(raw_packet_data)
    # TODO validate
    #marker, length, message_type = raw_packet_data.unpack('A16S>C')
    #raise ArgumentError, 'Marker is not all 0xFF' unless is_marker_all_0xff?(marker)
  end

  def self.register_subclass message_type_number
    @@subclasses[message_type_number] = self
  end
end

class LDPMessageHello < LDPMessage
  class UnpackedData < Struct.new(:message_code, :packet_length, :message_id, :data)
  end

  MESSAGE_CODE = 0x100
  UNPACK_STRING = '>S>S>La*'

  register_subclass MESSAGE_CODE

  attr_reader :message_id, :data

  def initialize(message_id, data)
    @message_id = message_id
    @data = data
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedData.new(*raw_packet_data.unpack(UNPACK_STRING))

    new(unpacked_data.message_id, unpacked_data.data)
  end

  def pack
    # TODO build
    raise MethodNotImplementedError
    #[marker, packet_length, message_type].pack(UNPACK_STRING)
  end
end
