module ApipieBindings
  module Model
    class Manager
      attr_reader :model, :app_config, :resource, :parent, :data

      def initialize(model, app_config, resource, parent, data)
        @model      = model
        @app_config = app_config
        @resource   = resource
        @parent     = parent
        @data       = stringify_keys(data)
      end

      def resource_config
        @app_config.resource_config(resource && resource.name)
      end

      def define_accessors!
        raise NotImplementedError
      end

      def api
        app_config.api
      end

      def logger
        api.log
      end

      private

      def stringify_keys(hash)
        ApipieBindings::IndifferentHash.deep_stringify_keys(hash)
      end

      def define_sub_resources!
        resource_config.sub_resources(data).each do |sub_resource|
          define_sub_resource_method(sub_resource)
        end
      end

      def define_model_method(name, &block)
        # ruby 1.9.3+ has signleton_class method, but we are not there yet
        singleton_class = model.instance_eval { class << self; self end }
        unless model.respond_to?(name)
          singleton_class.send(:define_method, name, &block)
        else
          logger.debug("method #{name} is already defined on model #{model}")
        end
      end

      def define_sub_resource_method(sub_resource)
        define_model_method(sub_resource.name) do
          Collection.new(model_manager.app_config,
                         model_manager.api.resource(sub_resource.name),
                         self,
                         sub_resource.conditions)
        end
      end

      def unique_keys
        resource_config.unique_keys
      end

      # Reduces the conditions to the minimal set that uniquely identifies the
      # resource.
      def unique_data(data)
        data = stringify_keys(data)
        present_keys = unique_keys.find do |keys|
          keys.all? { |key| data.has_key?(key) }
        end
        if present_keys
          present_keys.inject({}) do |unique_data, key|
            unique_data.update(key => data[key])
          end
        end
      end
    end
  end
end
