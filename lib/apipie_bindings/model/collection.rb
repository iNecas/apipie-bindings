module ApipieBindings
  module Model
    class Collection < Base
      def_delegators :model_manager, :find_or_create, :create, :find, :find_all

      def to_s
        "Collection of #{ super }: #{ model_manager.data.inspect }"
      end

      private

      def model_manager_class
        CollectionManager
      end
    end

    class CollectionManager < Manager
      def define_accessors!
      end

      def find_or_create(options)
        raw_search(search_options(options, true)).first || create(options)
      end

      def create(data)
        result = resource.action(:create).call(data.merge(self.data))
        build_member(result)
      end

      def find(conditions)
        find_all(conditions).first
      end

      def find_all(conditions)
        raw_search(search_options(conditions))
      end

      private

      def raw_search(search_options)
        resource.action(:index).call(search_options)['results'].map do |result|
          build_member(result)
        end
      end

      def search_options(conditions, unique = false)
        conditions = conditions.merge(data)
        if unique
          conditions = unique_conditions(conditions)
        end
        resource_config.search_options(conditions)
      end

      def build_member(member_data)
        Member.new(app_config, resource, self, member_data.merge(data))
      end

      def unique_keys
        resource_config.unique_keys
      end

      # Reduces the conditions to the minimal set that uniquely identifies the
      # resource.
      def unique_conditions(conditions)
        conditions = stringify_keys(conditions)
        # TODO: include the data from parent
        present_keys = unique_keys.find do |keys|
          keys.all? { |key| conditions.has_key?(key) }
        end
        present_keys.inject({}) do |unique_conditions, key|
          unique_conditions.update(key =>conditions[key])
        end
      end
    end
  end
end
