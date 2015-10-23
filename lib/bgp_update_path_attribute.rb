require './lib/slicer'

class BGPUpdatePathAttributePacked
  ADDITIONAL_LENGTH = 2
  OFFSET_OF_LENGTH_FIELD = 2
  SIZE_OF_LENGTH_FIELD = 1
  LENGTH_FIELD_UNPACK_STRING = 'C'

  attr_reader :packed_data

  def initialize(packet)
    @packed_data = packet.byteslice(0, slice_length(packet))
  end

  def slice_length(packet)
    attribute_length = packet.byteslice(OFFSET_OF_LENGTH_FIELD).unpack(LENGTH_FIELD_UNPACK_STRING).first
    attribute_length + SIZE_OF_LENGTH_FIELD + ADDITIONAL_LENGTH
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
    packed_attribute_enumerator = Slicer.new(packed_attributes, BGPUpdatePathAttributePacked)

    packed_attribute_enumerator.map do |packed_attribute|
      #new(unpack_prefix(packed_attribute), unpack_prefix_length(packed_route))
      packed_attribute
    end
  end
end
