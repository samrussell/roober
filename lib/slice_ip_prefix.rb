require './lib/slicer'

class SliceIPPrefixPacked
  OFFSET_OF_LENGTH_FIELD = 0
  SIZE_OF_LENGTH_FIELD = 1
  LENGTH_FIELD_UNPACK_STRING = 'C'

  attr_reader :packed_data

  def initialize(packet)
    @packed_data = packet.byteslice(0, slice_length(packet))
  end

  def slice_length(packet)
    prefix_length_in_bits = packet.byteslice(OFFSET_OF_LENGTH_FIELD).unpack(LENGTH_FIELD_UNPACK_STRING).first

    prefix_length_in_bytes = prefix_length_bits_to_bytes(prefix_length_in_bits)

    prefix_length_in_bytes + SIZE_OF_LENGTH_FIELD
  end

  private

  def prefix_length_bits_to_bytes(prefix_length_in_bits)
    prefix_length_in_bytes = prefix_length_in_bits / 8

    unless divisible_by_8?(prefix_length_in_bits)
      prefix_length_in_bytes += 1
    end

    prefix_length_in_bytes
  end

  def divisible_by_8?(number)
    number % 8 == 0
  end
end

class SliceIPPrefix
  attr_reader :prefix
  attr_reader :prefix_length

  def initialize(prefix, prefix_length)
    @prefix = prefix
    @prefix_length = prefix_length
  end


  def self.unpack(packed_routes)
    packed_route_enumerator = Slicer.new(packed_routes, SliceIPPrefixPacked)

    packed_route_enumerator.map do |packed_route|
      new(unpack_prefix(packed_route), unpack_prefix_length(packed_route))
    end
  end

  private

  def self.unpack_prefix_length(packed_route)
    packed_route.packed_data.byteslice(0).unpack('C')[0]
  end

  def self.unpack_prefix(packed_route)
    packed_prefix = packed_route.packed_data.byteslice(1..-1)

    unpacked_prefix_initial_bytes = packed_prefix.unpack('C*')

    pad_with_zeroes(unpacked_prefix_initial_bytes, 4)
  end

  def self.pad_with_zeroes(array, final_length)
    if array.size >= final_length
      number_of_zeroes_to_add = 0
    else
      number_of_zeroes_to_add = final_length - array.size
    end

    array + number_of_zeroes_to_add.times.map { 0 }
  end
end
