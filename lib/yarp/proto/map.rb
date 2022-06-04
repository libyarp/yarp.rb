# frozen_string_literal: true

module Yarp
  module Proto
    # Internal: Map implements an encoder and decoder for Yarp's Map values
    class Map
      def self.[](key, value)
        new(key, value)
      end

      def initialize(k_type, v_type)
        @soft_k = Proto::SOFT_TO_TYPE[k_type]
        raise ArgumentError, "invalid k_type #{k_type} for map key" if @soft_k.nil?
        raise ArgumentError, "unsupported key type #{k_type} for map key" unless Proto::VALID_HASH_KEYS.include? @soft_k

        @soft_v = Proto::SOFT_TO_TYPE[v_type]
        raise ArgumentError, "invalid v_type #{v_type} for map value" if @soft_v.nil?

        @k_type = k_type
        @v_type = v_type
      end

      def encode(into, value)
        raise "Map.encode called for non-hash value #{value.inspect}" unless value.is_a? Hash
        return into.write(Scalar.encode(0).tap { |v| v.setbyte(0, v.getbyte(0) | 0xC0) }) if value.empty?

        Proto.validate_hash!(value)

        k_buf = StringIO.new
        v_buf = StringIO.new
        value.keys
             .map { |k| Proto.convert!(k, @soft_k) }
             .each { |k| Proto.encode(k_buf, k, as: @k_type) }

        value.values
             .map { |v| Proto.convert!(v, @soft_v) }
             .each { |v| Proto.encode(v_buf, v, as: @v_type) }

        k_len = Scalar.encode_integer(nil, k_buf.length)
        v_len = Scalar.encode_integer(nil, v_buf.length)
        m_len = k_buf.length + k_len.length + v_buf.length + v_len.length
        head = Scalar.encode(m_len)
        head.setbyte(0, head.getbyte(0) | 0xC0)

        [head, k_len, k_buf.string, v_len, v_buf.string].each do |buf|
          into.write(buf)
        end
      end

      def decode(header, io)
        convert(self.class.decode(header, io))
      end

      def convert(value)
        value.to_h { |k, v| [Proto.convert!(k, @k_type), Proto.convert!(v, @v_type)] }
      end

      class << self
        def decode(header, io)
          size = Scalar.decode(header, io)
          return {} if size.zero?
          raise SizeTooLargeError if size >= Proto::SIZE_LIMIT

          r = LimitedIO.new(io, size)

          key_len = Scalar.decode(r.read(1), r)
          key_r = LimitedIO.new(r, key_len)
          keys = []
          loop do
            keys << Proto.decode(key_r, as: :any)
          rescue EOFError
            break
          end

          value_len = Scalar.decode(r.read(1), r)
          value_r = LimitedIO.new(r, value_len)
          values = []
          loop do
            values << Proto.decode(value_r, as: :any)
          rescue EOFError
            break
          end

          raise Error, "uneven map values" if keys.length != values.length

          keys.zip(values).to_h
        end
      end
    end
  end
end
