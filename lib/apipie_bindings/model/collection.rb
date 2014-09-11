module ApipieBindings
  module Model
    class Collection < Base
      include Enumerable

      def_delegators(:model_manager,
                     :find_or_create, :find, :find_by_uniq,
                     :create, :all, :where, :each,
                     :build)

      def to_s
        "Collection: #{ model_manager.description_with_parent }"
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
        find_by_uniq(options) || create(options)
      end

      def find_by_uniq(options)
        raw_search(search_options(options, true)).first
      end

      def create(data)
        build(data).tap { |member| member.save }
      end

      def find(conditions)
        find_all(conditions).first
      end

      def where(conditions)
        Collection.new(app_config, resource, self.model, data.merge(conditions))
      end

      def all
        raw_search(search_options)
      end

      def each(&block)
        all.each(&block)
      end

      def build(member_data = {})
        build_member(self.resource, data.merge(member_data))
      end

      def description
        resource.name.to_s
      end

      private

      def raw_search(search_options)
        search_options_with_required = fill_required_fields(resource.action(:index), search_options)
        resource.action(:index).call(search_options_with_required)['results'].map do |result|
          build(result)
        end
      end

      def search_options(conditions = {}, unique = false)
        conditions = conditions.merge(data)
        if unique
          conditions = unique_data(conditions)
          if conditions.nil?
            raise "Could not find unique data among #{data.inspect} to identify the resource"
          end
        end
        resource_config.search_options(conditions)
      end
    end
  end
end
