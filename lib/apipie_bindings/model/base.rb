require 'forwardable'

module ApipieBindings
  module Model

    class Base
      extend Forwardable

      attr_reader :_manager
      def_delegators '_manager.data', '[]', '[]='

      def initialize(api, resource = nil, parent = nil,  data = {})
        @_manager = model_manager_class.new(self, api, resource, parent, data)
        _manager.define_accessors!
      end

      def inspect
        to_s
      end

      def to_s
        _manager.resource.name
      end

      def to_hash
        _manager.data
      end

      private

      def model_manager_class
        raise NotImplementedError
      end
    end

  end
end
