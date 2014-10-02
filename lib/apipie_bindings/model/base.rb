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

      def method_missing(name, *args)
        if _manager.model_respond_to?(name)
          _manager.model_method_missing(name, *args)
        else
          super
        end
      end

      def respond_to_missing?(name, *args)
        super || _manager.model_respond_to?(name)
      end

      def methods
        # we don't convert the model_instance_methods to_sym because
        # they could pottentially be sourced from a user input
        super + _manager.model_instance_methods
      end

      private

      def model_manager_class
        raise NotImplementedError
      end
    end

  end
end
