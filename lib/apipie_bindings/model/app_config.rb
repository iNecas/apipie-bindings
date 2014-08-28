module ApipieBindings
  module Model
    class AppConfig
      attr_reader :api, :name

      def initialize(api, name = "Application")
        @api  = api
        @name = name
      end

      # @api override
      # @param resource_name [Symbol]
      # @return [Array<SubResource>]
      def sub_resources(resource_name, data)
        []
      end

      # @api override
      # Produces search options for the index action based on the conditions
      #
      # @param resource_name [Symbol]
      # @param conditions [Hash] - key-value conditions to produce the search query
      # @return [Hash] - search params to be setn to the index action.
      def search_options(resource_name, conditions)
        conditions
      end

      # @api override
      # @param resource_name [Symbol]
      # @return [Array<Array<String>>] - various combinations of
      #   params that uniquely identify the resource
      def unique_keys(resource_name)
        [%w[id], %w[name]]
      end

      # Helper method for producing the sub_resource objects
      def sub_resource(name, conditions = {})
        SubResource.new(name, conditions)
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
