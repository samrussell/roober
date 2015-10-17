class BGPUpdateWithdrawnRoute
  attr_reader :prefix
  attr_reader :prefix_length

  def initialize(prefix, prefix_length)
    @prefix = prefix
    @prefix_length = prefix_length
  end

  def self.unpack(packed_routes)
    routes = []
    offset = 0
    #TODO DRY this up, make an unpacker class
    while offset < packed_routes.length
      prefix_length_in_bits = packed_routes.getbyte(offset)
      #TODO yuck!
      prefix_length_in_bytes = prefix_length_in_bits/8 + handle_remainder(prefix_length_in_bits, 8)
      prefix = packed_routes.byteslice(offset+1, prefix_length_in_bytes)
      routes << new(prefix, prefix_length_in_bits)
      offset += 1 + prefix_length_in_bytes
    end

    routes
  end

  private

  def self.handle_remainder(number, divisor)
    if number % divisor > 0
      1
    else
      0
    end
  end
end
