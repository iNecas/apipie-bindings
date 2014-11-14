module ApipieBindings
  module Model
    class Manager
      attr_reader :model, :app_config, :resource, :parent, :data

      def initialize(model, app_config, resource, parent, data)
        @model         = model
        @app_config    = app_config
        @resource      = resource
        @parent        = parent
        @associated_collections = {}
        @data          = stringify_keys(data)
        @origin_data   = @data
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
          parts << parent._manager.description_with_parent
        end
        parts << description
        parts.join('/')
      end

      def params
        params = data.map do |key, value|
          ApipieBindings::Param.new(:name => key, :expected_type => 'string')
        end
        params_from_docs.inject(params) do |included_params, param|
          unless included_params.any? { |p| p.name.to_s == param.name.to_s }
            included_params << param
          else
            included_params
          end
        end
      end

      def params_from_docs
        action = [:create, :update].find { |a| resource.has_action?(a) }
        return [] unless action
        resource.action(action).all_params
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
        params = fill_required_fields(action, params)
        response = action.call(params)
        response_resource = resource_config.detect_response_resource(action, params, response)
        build_member(response_resource, response)
      end

      def changed?
        @origin_data != @data
      end

      def mark_unchanged!
        @origin_data = @data
      end

      def sub_resource_collection(sub_resource)
        @associated_collections[sub_resource.name] ||= build_collection(sub_resource.resource,
                                                               model,
                                                               sub_resource.conditions(self.model))
      end

      def model_method_missing(name, *args)
        raise NotImplementedError
      end

      def model_respond_to?(name)
        false
      end

      def model_instance_methods
        []
      end

      private

      def fill_required_fields(action, search_options)
        params_to_include = action.params_from_routes + action.all_params.find_all(&:required?)
        params_to_include.inject(search_options) do |ret_search_options, param|
          key = param.name.to_s
          if !ret_search_options.key?(key) && data.key?(key)
            ret_search_options.merge(key => data[key])
          else
            ret_search_options
          end
        end
      end

      def stringify_keys(hash)
        ApipieBindings::IndifferentHash.deep_stringify_keys(hash)
      end

      def define_associations!
        resource_config.associated_collections(data).each do |sub_resource|
          define_sub_resource_method(sub_resource)
        end
      end

      def define_model_method(name, &block)
        # ruby 1.9.3+ has signleton_class method, but we are not there yet
        singleton_class = model.instance_eval { class << self; self end }
        singleton_class.send(:define_method, name, &block)
      end

      def define_sub_resource_method(sub_resource)
        define_model_method(sub_resource.name) do
          _manager.sub_resource_collection(sub_resource)
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
