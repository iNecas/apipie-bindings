module ApipieBindings
  module Model
    class Collection < Base
      include Enumerable

      def_delegators(:_manager,
                     :find_or_create, :find, :find_by_uniq,
                     :create, :all, :where, :each, :reload,
                     :build, :save)

      def_delegators(:all, :delete, :<<)

      def to_s
        "Collection: #{ _manager.description_with_parent }"
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

      def reload
        @all = @origin_all = nil
      end

      def all
        return @all if @all
        @origin_all = @all = raw_search(search_options)
      end

      def all=(value)
        @all = value
      end

      def save
        ret = 0
        to_add.each do |added_member|
          ret += 1
          add!(added_member)
        end

        to_remove.each do |removed_member|
          ret += 1
          remove!(removed_member)
        end

        to_save do |changed_member|
          ret += 1
          save!(changed_mamber)
        end
      end

      def changed?
        return false if @all.nil?
        to_add.any? || to_remove.any? || to_save.any?
      end

      def to_add
        @all - @origin_all
      end

      def to_remove
        @origin_all - @all
      end

      def add!(member)
        # we need to know what association this collection represents: the resource
        # itself might not be enough: it might be in different roles: a user
        # can be author, editor, reader - add role to the collection details
        raise NotImplementedError, "how to add a resource to collection?"
      end

      def remove!(member)
        raise NotImplementedError, "how to remove a resource from collection"
      end

      def save!(member)
        raise NotImplementedError, "how to save a member inside a collection?"
      end

      def to_save
        (self.all - to_add - to_remove).find_all do |member|
          member._manager.changed?
        end
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
