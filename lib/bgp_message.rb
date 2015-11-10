require './lib/abstract_slice'
require './lib/bgp_open_optional_parameter'
require './lib/bgp_update_path_attribute'
require './lib/slice_ip_prefix'

class BGPMessagePacked < AbstractSlice
  OFFSET_OF_LENGTH_FIELD = 16
  SIZE_OF_LENGTH_FIELD = 2
  BODY_LENGTH_DIFFERENCE = -18
  LENGTH_FIELD_UNPACK_STRING = 'S>'

  protected

  def initial_length
    OFFSET_OF_LENGTH_FIELD + SIZE_OF_LENGTH_FIELD
  end

  def remainder_length
    @initial.byteslice(OFFSET_OF_LENGTH_FIELD, SIZE_OF_LENGTH_FIELD).unpack(LENGTH_FIELD_UNPACK_STRING).first + BODY_LENGTH_DIFFERENCE
  end
end

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
    self.class::MESSAGE_CODE
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
  class UnpackedData < Struct.new(:marker, :packet_length, :message_type,
    :bgp_version, :sender_as, :hold_time, :sender_id, :optional_parameters_length,
    :optional_parameters)
  end

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

  attr_reader :bgp_version
  attr_reader :sender_as
  attr_reader :hold_time
  attr_reader :sender_id

  register_subclass MESSAGE_CODE

  def initialize(bgp_version, sender_as, hold_time,
                 sender_id, optional_parameters)
    @bgp_version = bgp_version
    @sender_as = sender_as
    @hold_time = hold_time
    @sender_id = sender_id
    @packed_optional_parameters = optional_parameters
  end

  def packet_length
    MINIMUM_PACKET_LENGTH + optional_parameters.reduce(0) do |sum, optional_parameter|
      sum + optional_parameter.size
    end
  end

  def optional_parameters
    @optional_parameters ||= BGPOpenOptionalParameter.build_from_packet(@packed_optional_parameters)
  end

  def self.build_from_packet(raw_packet_data)
    unpacked_data = UnpackedData.new(*raw_packet_data.unpack(UNPACK_STRING))

    if bad_packet_length?(unpacked_data.packet_length)
      raise_error(:bgp_open_bad_length)
    elsif bad_optional_parameters_length?(unpacked_data.packet_length, unpacked_data.optional_parameters_length)
      raise_error(:bgp_open_bad_optional_parameters_length)
    elsif bad_version?(unpacked_data.bgp_version)
      raise_error(:bgp_open_bad_version)
    elsif bad_hold_time?(unpacked_data.hold_time)
      raise_error(:bgp_open_bad_hold_time)
    end

    new(unpacked_data.bgp_version, unpacked_data.sender_as, unpacked_data.hold_time,
      unpacked_data.sender_id, unpacked_data.optional_parameters)
  end

  private

  def self.bad_packet_length?(packet_length)
    packet_length < MINIMUM_PACKET_LENGTH
  end

  def self.bad_optional_parameters_length?(packet_length, optional_parameters_length)
    optional_parameters_length != packet_length - MINIMUM_PACKET_LENGTH
  end

  def self.bad_version?(bgp_version)
    bgp_version != BGP_VERSION
  end

  def self.bad_hold_time?(hold_time)
    hold_time != ZERO_HOLD_TIME && hold_time < MINIMUM_HOLD_TIME
  end

  def self.raise_error(error)
    raise BGPMessageError.new(error), ERROR_MESSAGES[error]
  end
end

class BGPMessageUpdate < BGPMessage
  ERROR_MESSAGES = {
  }

  MINIMUM_PACKET_LENGTH = 23
  MESSAGE_CODE = 2
  UNPACK_STRING = 'a16S>Ca*'
  WITHDRAWN_ROUTES_LENGTH_UNPACK_STRING = 'S>'
  WITHDRAWN_ROUTES_LENGTH_FIELD_SIZE = 2
  PATH_ATTRIBUTES_LENGTH_UNPACK_STRING = 'S>'
  PATH_ATTRIBUTES_LENGTH_FIELD_SIZE = 2

  attr_reader :packet_length

  register_subclass MESSAGE_CODE

  def initialize(marker, packet_length, message_type,
                 update_data)
    @packet_length = packet_length
    @update_data = update_data

    #validate_parameters
  end

  def withdrawn_routes
    @withdrawn_routes ||= unpack_withdrawn_routes
  end

  def unpack_withdrawn_routes
    packed_withdrawn_routes = start_of_packed_withdrawn_routes.byteslice(WITHDRAWN_ROUTES_LENGTH_FIELD_SIZE, withdrawn_routes_length)

    unpacked_withdrawn_routes = SliceIPPrefix.unpack(packed_withdrawn_routes, withdrawn_routes_length)
  end
  
  def withdrawn_routes_length
    @withdrawn_routes_length = start_of_packed_withdrawn_routes.unpack(WITHDRAWN_ROUTES_LENGTH_UNPACK_STRING)[0]
  end

  def start_of_packed_withdrawn_routes
    @update_data
  end

  def path_attributes
    @path_attributes ||= unpack_path_attributes
  end

  def unpack_path_attributes
    packed_path_attributes = start_of_packed_path_attributes.byteslice(PATH_ATTRIBUTES_LENGTH_FIELD_SIZE, path_attributes_length)

    unpacked_path_attributes = BGPUpdatePathAttribute.unpack(packed_path_attributes)
  end
  
  def path_attributes_length
    @path_attributes_length = start_of_packed_path_attributes.unpack(PATH_ATTRIBUTES_LENGTH_UNPACK_STRING)[0]
  end

  def start_of_packed_path_attributes
    @update_data.byteslice(WITHDRAWN_ROUTES_LENGTH_FIELD_SIZE + withdrawn_routes_length..-1)
  end

  def nlri
    @nlri ||= unpack_nlri
  end

  #TODO this is repetitive, shrink it down in refactor
  def unpack_nlri
    packed_nlri = start_of_packed_nlri

    unpacked_nlri = SliceIPPrefix.unpack(packed_nlri, packed_nlri.length)
  end
  
  def start_of_packed_nlri
    start_of_packed_path_attributes.byteslice(PATH_ATTRIBUTES_LENGTH_FIELD_SIZE + path_attributes_length..-1)
  end

  def self.build_from_packet(raw_packet_data)
    new(*raw_packet_data.unpack(UNPACK_STRING))
  end

  private

  def validate_parameters
    #TODO build tests for this
  end
end

class BGPMessageKeepalive < BGPMessage
  MESSAGE_CODE = 4

  register_subclass MESSAGE_CODE

  def self.build_from_packet(raw_packet_data)
    new
  end
end
