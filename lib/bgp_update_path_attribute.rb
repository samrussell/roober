require './lib/string_slicer'

class BGPUpdatePathAttributePacked < AbstractSlice
  OFFSET_OF_LENGTH_FIELD = 2
  SIZE_OF_LENGTH_FIELD = 1
  BODY_LENGTH_DIFFERENCE = 0
  LENGTH_FIELD_UNPACK_STRING = 'C'

  protected

  def initial_length
    OFFSET_OF_LENGTH_FIELD + SIZE_OF_LENGTH_FIELD
  end

  def remainder_length
    @initial.byteslice(OFFSET_OF_LENGTH_FIELD, SIZE_OF_LENGTH_FIELD).unpack(LENGTH_FIELD_UNPACK_STRING).first + BODY_LENGTH_DIFFERENCE
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
      packed_attribute
    end
  end
end
