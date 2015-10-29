require './lib/io_slicer'

class SliceIPPrefixExtractor
  OFFSET_OF_LENGTH_FIELD = 0
  SIZE_OF_LENGTH_FIELD = 1
  LENGTH_FIELD_UNPACK_STRING = 'C'

  def initialize(input_stream)
    @input_stream = input_stream
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
    prefix_length_in_bits = @header.byteslice(OFFSET_OF_LENGTH_FIELD, SIZE_OF_LENGTH_FIELD).unpack(LENGTH_FIELD_UNPACK_STRING).first

    prefix_length_in_bytes = prefix_length_bits_to_bytes(prefix_length_in_bits)
  end

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


  def self.unpack(packed_routes, packed_routes_length)
    packed_route_enumerator = StringSlicer.new(packed_routes, packed_routes_length, SliceIPPrefixExtractor)

    packed_route_enumerator.map do |packed_route|
      new(unpack_prefix(packed_route), unpack_prefix_length(packed_route))
    end
  end

  private

  def self.unpack_prefix_length(packed_route)
    packed_route.byteslice(0).unpack('C')[0]
  end

  def self.unpack_prefix(packed_route)
    packed_prefix = packed_route.byteslice(1..-1)

    unpacked_prefix_initial_bytes = packed_prefix.unpack('C*')

    pad_with_zeroes(unpacked_prefix_initial_bytes, 4)
  end

  def self.pad_with_zeroes(array, final_length)
    array += [0] while array.size < final_length

    array
  end
end
