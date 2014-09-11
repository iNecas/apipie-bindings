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
      def sub_resources(data)
        []
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
      def sub_resource(name, conditions = {})
        SubResource.new(name, conditions)
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

      class SubResource
        attr_reader :name, :conditions

        def initialize(resource_name, conditions)
          raise ArgumentError unless resource_name.is_a? Symbol
          @name       = resource_name
          @conditions = conditions
        end
      end
    end
  end
end
