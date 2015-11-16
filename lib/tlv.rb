class TLV
  CODE_PACKED_LENGTH = 1
  LENGTH_PACKED_LENGTH = 1
  UNPACK_STRING = 'CCa*'

  attr_reader :code
  attr_reader :data

  def initialize(code, data)
    @code = code
    @data = data
  end

  def pack
    [code, @data.length, data].pack(UNPACK_STRING)
  end

  def packed_length
    CODE_PACKED_LENGTH + LENGTH_PACKED_LENGTH + @data.length
  end

  def self.unpack(packed_tlv)
    tlv_code, tlv_length, rest_of_message = packed_tlv.unpack(UNPACK_STRING)
    tlv_data = rest_of_message.byteslice(0, tlv_length)

    raise ArgumentError, 'Wrong TLV length' if tlv_length != tlv_data.length

    new(tlv_code, tlv_data)
  end
end
