module ApipieBindings
  module Model
    class Member < Base
      def_delegators :model_manager, :save, :destroy, :reload

      def to_s
        "Member: #{ model_manager.description_with_parent }"
      end

      private

      def model_manager_class
        MemberManager
      end
    end

    class MemberManager < Manager
      def save
        if data['id']
          new_model = call_action(:update, self.data)
        else
          new_model = call_action(:create, self.data)
        end
        new_data = new_model.to_hash
        new_keys = new_data.keys - @data.keys
        define_data_accessors!(new_keys)
        @data = data.merge(new_data)
        model
      end

      def destroy
        call_action(:destroy)
        model
      end

      def reload
        reloaded_model = call_action(:show)
        @data = data.merge(reloaded_model.to_hash)
        model
      end

      def description
        resource_config.description(data)
      end

      def define_custom_methods!
        resource_config.custom_methods.each do |name, block|
          define_model_method(name) do |params = {}|
            block.call(self, params)
          end
        end
      end

      def define_action_methods!
        resource.actions.each do |action|
          next if [:index, :show, :update, :delete].include?(action.name)
          define_model_method(action.name) do |params = {}|
            model_manager.call_action(action.name, params)
          end
        end
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
        define_custom_methods!
        define_action_methods!
        define_sub_resources!
        define_data_accessors!
      end

      def unique_attributes
        unique_data(self.data)
      end
    end
  end
end
