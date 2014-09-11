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

      def description
        raise NotImplementedError
      end

      def description_with_parent
        parts = []
        if parent
          parts << parent.model_manager.description_with_parent
        end
        parts << description
        parts.join('/')
      end

      def build_member(resource, data)
        if self.resource.name == resource.name
          parent = self.model
        else
          parent = build_collection(resource)
        end
        Member.new(app_config, resource, parent, data)
      end

      def build_collection(resource, parent = app_config.app, data = {})
        Collection.new(app_config, resource, parent, data)
      end

      def call_action(action_name, params = {})
        action = resource.action(action_name)
        params = fill_required_fields(action, self.data.merge(params))
        response = action.call(params)
        response_resource = resource_config.detect_response_resource(action, params, response)
        build_member(response_resource, response)
      end

      private

      def fill_required_fields(action, search_options)
        action.all_params.inject(search_options) do |ret_search_options, param|
          key = param.name.to_s
          if param.required? && !ret_search_options.key?(key) && data.key?(key)
            ret_search_options.merge(key => data[key])
          else
            ret_search_options
          end
        end
      end

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
          model_manager.build_collection(model_manager.api.resource(sub_resource.name),
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
