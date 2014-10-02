module ApipieBindings
  module Model
    class Member < Base
      def_delegators :_manager, :save, :destroy, :reload

      def to_s
        "Member: #{ _manager.description_with_parent }"
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
        @data = data.merge(new_data)
        mark_unchanged!
        model
      end

      def destroy
        call_action(:destroy)
        model
      end

      def reload
        reloaded_model = call_action(:show)
        @data = data.merge(reloaded_model.to_hash)
        mark_unchanged!
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
            _manager.call_action(action.name, params)
          end
        end
      end

      def model_method_missing(name, *args)
        if model_respond_to?(name)
          call_data_method(name, *args)
        else
          raise NotImplementedError, "#{name}"
        end
      end

      def model_respond_to?(name)
        model_instance_methods.include?(name.to_s)
      end

      def model_instance_methods
        data_with_unset.keys.inject([]) do |ret, key|
          ret << key << "#{key}="
        end
      end

      def call_data_method(name, *args)
        name = name.to_s
        key = name.sub(/=$/, '')
        if name.end_with?('=')
          raise ArgumentError, "wrong number of arguments: #{args.size}, expected 1" unless args.size == 1
          @data[key] = args.first
        else
          raise ArgumentError, "wrong number of arguments: #{args.size}, expected 0" unless args.size == 0
          @data[key]
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
        define_associations!
        define_action_methods!
        define_custom_methods!
      end

      def unique_attributes
        unique_data(self.data)
      end
    end
  end
end
