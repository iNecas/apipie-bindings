module ApipieBindings
  module Model
    class AppConfig
      attr_reader :api, :name, :resource_configs

      def initialize(api, name = "Application")
        @api  = api
        @name = name
        @resource_config_mapping = {}
      end

      # @api override
      def resource_config_classes
        [Model::ResourceConfig]
      end

      def resource_config(resource_name)
        if @resource_config_mapping.key?(resource_name)
          @resource_config_mapping[resource_name]
        else
          if resource_config = find_resource_config(resource_name)
            @resource_config_mapping[resource_name] = resource_config
          else
            raise "Could not find resource configuration for #{resource_name}"
          end
          resource_config
        end
      end

      private

      def find_resource_config(resource_name)
        self.resource_config_classes.each do |config_class|
          config = config_class.new(@api, resource_name)
          if config.confines?
            return config
          end
        end
        return nil
      end
    end

  end
end
