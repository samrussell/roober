require './lib/abstract_slice'
require './lib/string_slicer'
require './lib/ldp_parameter'

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
  class UnpackedLDPMessageHelloData < Struct.new(:message_code, :message_length, :message_id, :common_tlv_type, :common_tlv_length, :hold_time, :common_flags, :packed_optional_parameters)
  end

  MESSAGE_CODE = 0x100
  UNPACK_STRING = 'S>S>L>S>S>S>S>a*'
  PACK_STRING = 'S>S>L>S>S>S>S>'

  register_subclass MESSAGE_CODE

  attr_reader :message_id, :hold_time

  def initialize(message_id, hold_time, targeted, request_targeted, packed_optional_parameters)
    @message_id = message_id
    @hold_time = hold_time
    @targeted = targeted
    @request_targeted = request_targeted
    @packed_optional_parameters = packed_optional_parameters
  end

  def targeted?
    @targeted
  end

  def request_targeted?
    @request_targeted
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedLDPMessageHelloData.new(*raw_packet_data.unpack(UNPACK_STRING))

    # TODO flags needs its own class
    targeted = (unpacked_data.common_flags & 0x8000) != 0
    request_targeted = (unpacked_data.common_flags & 0x4000) != 0
    new(unpacked_data.message_id,
        unpacked_data.hold_time,
        targeted,
        request_targeted,
        unpacked_data.packed_optional_parameters
       )
  end

  def pack
    common_tlv_type = 0x400
    common_tlv_length = 4
    message_length = 4 + (4 + common_tlv_length) + @packed_optional_parameters.length
    common_flags = 0
    common_flags += 0x8000 if targeted?
    common_flags += 0x4000 if request_targeted?
    [
      MESSAGE_CODE,
      message_length,
      @message_id,
      common_tlv_type,
      common_tlv_length,
      @hold_time,
      common_flags
    ].pack(PACK_STRING) +
      @packed_optional_parameters
  end
end

class LDPMessageInitialization < LDPMessage
  class UnpackedLDPMessageInitializationData < Struct.new(:message_code, :packet_length, :message_id, :data)
  end

  MESSAGE_CODE = 0x200
  UNPACK_STRING = 'S>S>L>a*'
  PACK_STRING = 'S>S>L>'

  register_subclass MESSAGE_CODE

  attr_reader :message_id, :data

  def initialize(message_id, data)
    @message_id = message_id
    @data = data
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedLDPMessageInitializationData.new(*raw_packet_data.unpack(UNPACK_STRING))

    new(unpacked_data.message_id,
        unpacked_data.data,
       )
  end

  def pack
    message_length = 4 + (@data && @data.length).to_i

    [
      MESSAGE_CODE,
      message_length,
      message_id,
    ].pack(PACK_STRING) +
      @data
  end
end

class LDPMessageKeepalive < LDPMessage
  class UnpackedLDPMessageKeepaliveData < Struct.new(:message_code, :packet_length, :message_id, :data)
  end

  MESSAGE_CODE = 0x201
  UNPACK_STRING = 'S>S>L>'
  PACK_STRING = 'S>S>L>'

  register_subclass MESSAGE_CODE

  attr_reader :message_id, :data

  def initialize(message_id, data)
    @message_id = message_id
    @data = data
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedLDPMessageKeepaliveData.new(*raw_packet_data.unpack(UNPACK_STRING))

    new(unpacked_data.message_id,
        unpacked_data.data,
       )
  end

  def pack
    message_length = 4

    [
      MESSAGE_CODE,
      message_length,
      message_id,
    ].pack(PACK_STRING)
  end
end

class LDPMessageAddress < LDPMessage
  class UnpackedLDPMessageAddressData < Struct.new(:message_code, :packet_length, :message_id, :address_list_packed)
  end

  MESSAGE_CODE = 0x300
  UNPACK_STRING = 'S>S>L>a*'
  PACK_STRING = 'S>S>L>'

  register_subclass MESSAGE_CODE

  attr_reader :message_id, :address_list

  def initialize(message_id, address_list)
    @message_id = message_id
    @address_list = address_list
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedLDPMessageAddressData.new(*raw_packet_data.unpack(UNPACK_STRING))

    address_list = LDPParameter.build_from_packet(unpacked_data.address_list_packed)

    new(unpacked_data.message_id,
        address_list
       )
  end

  def pack
    address_list_packed = address_list.pack
    message_length = 4 + address_list_packed.length

    [
      MESSAGE_CODE,
      message_length,
      message_id,
    ].pack(PACK_STRING) +
      address_list_packed
  end
end

class LDPMessageLabelMapping < LDPMessage
  class UnpackedLDPMessageLabelMappingData < Struct.new(:message_code, :packet_length, :message_id, :parameters_packed)
  end

  MESSAGE_CODE = 0x400
  UNPACK_STRING = 'S>S>L>a*'
  PACK_STRING = 'S>S>L>'

  register_subclass MESSAGE_CODE

  attr_reader :message_id

  def initialize(message_id, fec_parameter, label_parameter)
    @message_id = message_id
    @fec_parameter = fec_parameter
    @label_parameter = label_parameter
  end

  def prefixes
    @fec_parameter.prefixes
  end

  def label
    @label_parameter.label
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedLDPMessageLabelMappingData.new(*raw_packet_data.unpack(UNPACK_STRING))

    raw_parameters = StringSlicer.new(unpacked_data.parameters_packed, unpacked_data.parameters_packed.length, LDPParameterPacked).to_a

    fec_parameter = LDPParameter.build_from_packet(raw_parameters[0])
    label_parameter = LDPParameter.build_from_packet(raw_parameters[1])

    new(unpacked_data.message_id,
        fec_parameter,
        label_parameter
       )
  end

  def pack
    parameters_packed = @fec_parameter.pack + @label_parameter.pack
    message_length = 4 + parameters_packed.length

    [
      MESSAGE_CODE,
      message_length,
      message_id,
    ].pack(PACK_STRING) +
      parameters_packed
  end
end
