module ApipieBindings
  module Model
    class Member < Base
      def_delegators :model_manager, :save

      def to_s
        "Member of #{ super }: #{ model_manager.data.inspect }"
      end

      private

      def model_manager_class
        MemberManager
      end
    end

    class MemberManager < Manager
      def save
        raise NotImplementedError
      end

      def defined_data_accessors!
        data.each_key do |key|
          define_model_method(key) { self[key] }
          define_model_method("#{key}=") { |value| self[key] = value }
        end
      end

      def define_accessors!
        define_sub_resources!
        defined_data_accessors!
      end
    end
  end
end
