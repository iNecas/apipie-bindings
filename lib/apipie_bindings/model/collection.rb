module ApipieBindings
  module Model
    class Collection < Base
      include Enumerable

      def_delegators(:model_manager,
                     :find_or_create, :create, :find, :all, :where, :each,
                     :build)

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
        build(result).tap { |member| member.save }
      end

      def find(conditions)
        find_all(conditions).first
      end

      def where(conditions)
        Collection.new(app_config, resource, self, data.merge(conditions))
      end

      def all
        raw_search(search_options)
      end

      def each(&block)
        all.each(&block)
      end

      def build(member_data = {})
        Member.new(app_config, resource, self, member_data.merge(data))
      end

      private

      def raw_search(search_options)
        resource.action(:index).call(search_options)['results'].map do |result|
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
