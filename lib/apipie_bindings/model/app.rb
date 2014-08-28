module ApipieBindings
  module Model
    class App < Base
      def to_s
        @data.fetch(:name, 'App')
      end

      private

      def model_manager_class
        AppManager
      end
    end

    class AppManager < Manager
      def define_accessors!
        define_sub_resources!
      end
    end
  end
end
