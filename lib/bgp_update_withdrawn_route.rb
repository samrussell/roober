require './lib/slicer'

class BGPUpdateWithdrawnRoutePacked
  attr_reader :packed_data

  def initialize(packet)
    @packed_data = packet.byteslice(0, slice_length(packet))
  end

  def slice_length(packet)
    length_offset = 0

    length_size = 1

    prefix_length_in_bits = packet.byteslice(length_offset).unpack('C')[0]

    prefix_length_in_bytes = prefix_length_in_bits / 8

    if prefix_length_in_bits % 8 != 0
      round_up = 1
    else
      round_up = 0
    end

    prefix_length_in_bytes += round_up

    prefix_length_in_bytes + length_size
  end
end

class BGPUpdateWithdrawnRoute
  attr_reader :prefix
  attr_reader :prefix_length

  def initialize(prefix, prefix_length)
    @prefix = prefix
    @prefix_length = prefix_length
  end


  def self.unpack(packed_routes)
    #TODO doesn't work, need to take a block for prefix length
    packed_route_enumerator = Slicer.new(packed_routes, BGPUpdateWithdrawnRoutePacked)

    packed_route_enumerator.map do |packed_route|
      new(unpack_prefix(packed_route), packed_route.packed_data.byteslice(0).unpack('C')[0])
    end
  end

  private

  def self.unpack_prefix(packed_route)
    prefix = packed_route.packed_data.byteslice(1..-1).unpack('C*')
    prefix += (4 - prefix.length).times.map { 0 }
  end
end
