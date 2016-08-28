require './lib/abstract_slice'
require 'socket'
require 'ipaddr'

class LDPPacked < AbstractSlice
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

class LDPParameter
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

class LDPParameterIPv4Address < LDPParameter
  class UnpackedLDPParameterIPv4Address < Struct.new(:code, :parameter_length, :ip_address_packed)
  end

  PARAMETER_CODE = 0x401
  DEFAULT_LENGTH = 4
  UNPACK_STRING = 'S>S>L>'
  PACK_STRING = 'S>S>L>'

  register_subclass PARAMETER_CODE

  attr_reader :address

  def initialize(ip_address_packed)
    @address= IPAddr.new(ip_address_packed, Socket::PF_INET)
  end

  def pack
    [PARAMETER_CODE, DEFAULT_LENGTH, address.to_i].pack(PACK_STRING)
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedLDPParameterIPv4Address.new(*raw_packet_data.unpack(UNPACK_STRING))

    new(unpacked_data.ip_address_packed)
  end
end
