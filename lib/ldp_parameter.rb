require './lib/abstract_slice'
require './lib/string_slicer'
require 'socket'
require 'ipaddr'

class LDPParameterPacked < AbstractSlice
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
    # TODO change from packed to hton
    # address here is an int, not a string
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

class LDPParameterAddressList < LDPParameter
  class UnpackedLDPParameterAddressList < Struct.new(:code, :parameter_length, :family, :address_list_packed)
  end

  class AddressSlice < AbstractSlice
    def initial_length
      4
    end

    def remainder_length
      0
    end
  end

  PARAMETER_CODE = 0x101
  UNPACK_STRING = 'S>S>S>a*'
  PACK_STRING = 'S>S>S>'
  FAMILY_IPV4 = 1

  register_subclass PARAMETER_CODE

  attr_reader :addresses

  def initialize(addresses)
    @addresses = addresses
  end

  def pack
    packed_addresses = addresses.map(&:hton).join
    parameter_length = 2 + packed_addresses.length

    [PARAMETER_CODE, parameter_length, FAMILY_IPV4].pack(PACK_STRING) +
      packed_addresses
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedLDPParameterAddressList.new(*raw_packet_data.unpack(UNPACK_STRING))

    raise Exception("Only support IPv4") unless unpacked_data.family == FAMILY_IPV4

    addresses = StringSlicer.new(unpacked_data.address_list_packed, unpacked_data.parameter_length, AddressSlice).map do |packed_address|
      address_as_int = packed_address.unpack("L>")[0]
      IPAddr.new(address_as_int, Socket::PF_INET)
    end

    new(addresses)
  end
end

class LDPParameterCommonSession < LDPParameter
  class UnpackedLDPParameterCommonSession < Struct.new(:code, :length, :protocol_version, :keepalive_time, :flags, :path_vector_limit, :max_pdu_length, :lsr_id, :label_space_id)
  end

  PARAMETER_CODE = 0x500
  DEFAULT_LENGTH = 14
  UNPACK_STRING = 'S>S>S>S>CCS>L>S>'
  PACK_STRING = 'S>S>S>S>CCS>L>S>'

  register_subclass PARAMETER_CODE

  attr_reader :protocol_version, :keepalive_time, :flags, :path_vector_limit, :max_pdu_length, :lsr_id, :label_space_id

  def initialize(protocol_version, keepalive_time, flags, path_vector_limit, max_pdu_length, lsr_id, label_space_id)
    @protocol_version = protocol_version
    @keepalive_time = keepalive_time
    @flags = flags
    @path_vector_limit = path_vector_limit
    @max_pdu_length = max_pdu_length
    @lsr_id = IPAddr.new(lsr_id, Socket::PF_INET)
    @label_space_id = label_space_id
  end

  def pack
    [
      PARAMETER_CODE,
      DEFAULT_LENGTH,
      protocol_version,
      keepalive_time,
      flags,
      path_vector_limit,
      max_pdu_length,
      lsr_id.to_i,
      label_space_id
    ].pack(PACK_STRING)
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedLDPParameterCommonSession.new(*raw_packet_data.unpack(UNPACK_STRING))

    new(unpacked_data.protocol_version,
        unpacked_data.keepalive_time,
        unpacked_data.flags,
        unpacked_data.path_vector_limit,
        unpacked_data.max_pdu_length,
        unpacked_data.lsr_id,
        unpacked_data.label_space_id
       )
  end
end

