module ApipieBindings
  module Model
    class Member < Base
      def_delegators :model_manager, :save

      def to_s
        "Member of #{ super }: #{ model_manager.unique_attributes.inspect }"
      end

      private

      def model_manager_class
        MemberManager
      end
    end

    class MemberManager < Manager
      def save
        if data['id']
          new_data = resource.action(:update).call(data)
        else
          new_data = resource.action(:create).call(data)
        end
        new_keys = new_data.keys - @data.keys
        define_data_accessors!(new_keys)
        @data = data.merge(new_data)
      end

      def define_data_accessors!(keys = nil)
        keys ||= data_with_unset.keys
        keys.each do |key|
          define_model_method(key) { self[key] }
          define_model_method("#{key}=") { |value| self[key] = value }
        end
      end

      def data_with_unset
        return data unless resource.action(:create)
        resource.action(:create).all_params.inject(data) do |data_with_unset, param|
          if data_with_unset.key?(param.name.to_s)
            data_with_unset
          else
            data_with_unset.merge(param.name.to_s => nil)
          end
        end
      end

      def define_accessors!
        define_sub_resources!
        define_data_accessors!
      end

      def unique_attributes
        unique_data(self.data)
      end
    end
  end
end
