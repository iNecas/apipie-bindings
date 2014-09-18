module ApipieBindings
  module Model
    class ResourceConfig
      attr_reader :api, :resource_name

      def initialize(api, resource_name)
        @api           = api
        @resource_name = resource_name
      end

      def confines?
        true # this is a default one
      end

      # @api override
      # @return [Array<SubResource>]
      def associated_collections(data)
        if @resource_name
          api.resources.find_all do |resource|
            index_action = resource.action(:index)
            index_action && index_action.all_params.any? { |p| p.name == primary_id }
          end.map { |resource| associated_collection(resource) }
        else
          # not actual resource - it's the member that represents the app itself
          api.resources.map { |resource| associated_collection(resource) }
        end
      end

      # @api override
      # Produces search options for the index action based on the conditions
      #
      # @param conditions [Hash] - key-value conditions to produce the search query
      # @return [Hash] - search params to be setn to the index action.
      def search_options(conditions)
        conditions
      end

      # @api override
      # @param resource_name [Symbol]
      # @return [Array<Array<String>>] - various combinations of
      #   params that uniquely identify the resource
      def unique_keys
        [%w[id], %w[name]]
      end

      def description(data)
        data['name'] || data['id']
      end

      # Helper method for producing the sub_resource objects
      def associated_collection(resource)
        AssociatedCollection.new(resource)
      end

      # @api override
      # @param [ApipieBindings::Action] action called
      # @param [Hash] params used with the call
      # @param [Hash] returned data from the called action
      # @return What resource should be used to represent the output of the action
      #    by default, the resource of the original action is used
      def detect_response_resource(action, params, response)
        api.resource(action.resource)
      end

      # @api_override
      # @return [Hash<Symbol,Proc>] names and procs to define custom methods on
      #   the resource
      def custom_methods
        {}
      end

      def extracted_ids(data)
        data.inject({}) do |hash, (k, v)|
          case k
          when 'id'
            hash.update(primary_id => v)
          when /_id$/
            hash.update(k => v)
          else
            hash
          end
        end
      end

      def primary_id
        binding.pry unless resource_name
        "#{ApipieBindings::Inflector.singularize(resource_name)}_id"
      end

      class AssociatedCollection
        attr_reader :resource

        def initialize(resource)
          raise ArgumentError unless resource.is_a? Resource
          @resource = resource
        end

        def name
          @resource.name
        end

        def conditions(model)
          extracted_ids = model.model_manager.resource_config.extracted_ids(model.to_hash)
          index_params = resource.action(:index).all_params
          related_ids = extracted_ids.keep_if do |id_name, value|
            index_params.any? { |p| p.name == id_name }
          end

          related_ids
        end
      end
    end
  end
end
