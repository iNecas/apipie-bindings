module ApipieBindings

  class IndifferentHash < Hash

    def initialize(constructor = {})
      super()
      merge!(constructor)
    end

    def [](k)
      if has_key?(k)
        convert_value(super(k))
      elsif k.is_a?(Symbol) && has_key?(k.to_s)
        convert_value(super(k.to_s))
      elsif k.is_a?(String) && has_key?(k.to_sym)
        convert_value(super(k.to_sym))
      else
        convert_value(super(k))
      end
    end

    def self.deep_stringify_keys(object)
      case object
      when Hash
        object.each_with_object({}) do |(key, value), result|
          result[key.to_s] = deep_stringify_keys(value)
        end
      when Array
        object.map {|e| deep_stringify_keys(e) }
      else
        object
      end
    end

    private

    def convert_value(value)
      if value.kind_of?(Hash) && !value.is_a?(IndifferentHash)
        IndifferentHash.new(value)
      elsif value.kind_of?(Array)
        value.map { |v| convert_value(v) }
      else
        value
      end
    end
  end
end
