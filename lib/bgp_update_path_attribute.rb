require './lib/string_slicer'

class BGPUpdatePathAttributePacked
  ADDITIONAL_LENGTH = 2
  OFFSET_OF_LENGTH_FIELD = 2
  SIZE_OF_LENGTH_FIELD = 1
  LENGTH_FIELD_UNPACK_STRING = 'C'

  attr_reader :packed_data

  def initialize(input_stream)
    @input_stream = input_stream
    #@packed_data = packet.byteslice(0, slice_length(packet))
  end

  def call
    read_header

    read_body

    @header + @body
  end


  private

  def read_header
    @header = @input_stream.read(OFFSET_OF_LENGTH_FIELD + SIZE_OF_LENGTH_FIELD)
  end

  def read_body
    @body = @input_stream.read(body_length)
  end

  def body_length
    @header.byteslice(OFFSET_OF_LENGTH_FIELD).unpack(LENGTH_FIELD_UNPACK_STRING).first
  end
end

class BGPUpdatePathAttribute
  attr_reader :prefix
  attr_reader :prefix_length

  def initialize(prefix, prefix_length)
    @prefix = prefix
    @prefix_length = prefix_length
  end


  def self.unpack(packed_attributes)
    packed_attribute_enumerator = StringSlicer.new(packed_attributes, packed_attributes.length, BGPUpdatePathAttributePacked)

    packed_attribute_enumerator.map do |packed_attribute|
      #new(unpack_prefix(packed_attribute), unpack_prefix_length(packed_route))
      packed_attribute
    end
  end
end
