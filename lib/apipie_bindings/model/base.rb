require 'forwardable'

module ApipieBindings
  module Model

    class Base
      extend Forwardable

      attr_reader :model_manager
      def_delegators 'model_manager.data', '[]', '[]='

      def initialize(api, resource = nil, parent = nil,  data = {})
        @model_manager = model_manager_class.new(self, api, resource, parent, data)
        model_manager.define_accessors!
      end

      def inspect
        to_s
      end

      def to_s
        model_manager.resource.name
      end

      def to_hash
        model_manager.data
      end

      private

      def model_manager_class
        raise NotImplementedError
      end
    end

  end
end
