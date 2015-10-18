class Slicer
  LENGTH_FIELD_UNPACK_STRING = {
    1 => 'C',
    2 => 'S>',
    4 => 'L>'
  }

  include Enumerable

  def initialize(packed_data, prefix_length = 0, length_field_length = 1)
    @packed_data = packed_data
    @prefix_length = prefix_length
    @length_field_length = length_field_length
  end

  def each
    while item = next_item
      yield item
    end
  end

  private

  def next_item
    return nil if @packed_data.nil? || @packed_data.length == 0
    data_length = extract_length
    block_length = data_length + @length_field_length + @prefix_length
    raise ArgumentError, 'Not enough data to unpack' if data_length > @packed_data.length
    unpacked_data = @packed_data.byteslice(0, block_length)
    @packed_data = @packed_data.byteslice(block_length..-1)
    unpacked_data
  end

  def extract_length
    unpack_string = LENGTH_FIELD_UNPACK_STRING[@length_field_length]
    @packed_data.byteslice(@prefix_length, @length_field_length).unpack(unpack_string)[0]
  end
end
