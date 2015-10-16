class TLV
  CODE_PACKED_LENGTH = 1
  LENGTH_PACKED_LENGTH = 1

  attr_reader :code
  attr_reader :data

  def initialize(code, data)
    @code = code
    @data = data
  end

  def packed_length
    CODE_PACKED_LENGTH + LENGTH_PACKED_LENGTH + @data.length
  end

  def self.unpack(packed_tlv)
    tlv_code, tlv_length = packed_tlv.unpack('CC')
    tlv_data = packed_tlv.byteslice(2, tlv_length)

    raise ArgumentError, 'Wrong TLV length' if tlv_length != tlv_data.length

    new(tlv_code, tlv_data)
  end
end
