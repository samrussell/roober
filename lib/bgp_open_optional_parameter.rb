require './lib/tlv'

class BGPOpenOptionalParameter < TLV

  def self.build_from_packet(optional_parameters_block)
    #TODO not idiomatic, redo
    parameters = []
    offset = 0
    while offset < optional_parameters_block.length
      parameter = unpack(optional_parameters_block.byteslice(offset..-1))
      offset += parameter.packed_length
      parameters << parameter
    end

    parameters
  end
end
