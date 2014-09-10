module ApipieBindings
  module Model
    class App < Base
      def to_s
        model_manager.app_config.name
      end

      private

      def model_manager_class
        AppManager
      end
    end

    class AppManager < Manager
      def description
        model.to_s
      end

      def define_accessors!
        define_sub_resources!
      end
    end
  end
end
