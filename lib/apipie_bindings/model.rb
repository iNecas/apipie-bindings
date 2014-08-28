require 'forwardable'

module ApipieBindings
  class Model
    extend Forwardable

    attr_reader :model_manager
    def_delegators 'model_manager.data', '[]', '[]='

    def initialize(api, resource = nil, parent = nil,  data = {})
      @model_manager = model_manager_class.new(self, api, resource, parent, data)
      model_manager.define_accessors!
    end

    def inspect
      to_s
    end

    def to_s
      model_manager.resource.name
    end

    private

    def model_manager_class
      raise NotImplementedError
    end

    class Collection < Model

      def_delegators :model_manager, :find_or_create, :create, :search

      def to_s
        "Collection of #{ super }: #{ model_manager.data.inspect }"
      end

      private

      def model_manager_class
        CollectionManager
      end
    end

    class Member < Model

      def_delegators :model_manager, :save

      def to_s
        "Member of #{ super }: #{ model_manager.data.inspect }"
      end

      private

      def model_manager_class
        MemberManager
      end
    end

    class App < Model
      def to_s
        @data.fetch(:name, 'App')
      end

      private

      def model_manager_class
        AppManager
      end
    end

    class Manager
      attr_reader :model, :api, :resource, :parent, :data

      def initialize(model, api, resource, parent, data)
        @model    = model
        @api      = api
        @resource = resource
        @parent   = parent
        @data     = stringify_keys(data)
      end

      def define_accessors!
        raise NotImplementedError
      end

      private

      def define_model_method(name, &block)
        # ruby 1.9.3+ has signleton_class method, but we are not there yet
        singleton_class = model.instance_eval { class << self; self end }
        unless model.respond_to?(name)
          singleton_class.send(:define_method, name, &block)
        else
          warn("method #{name} is already defined on model #{model}")
        end
      end

      def stringify_keys(hash)
        ApipieBindings::IndifferentHash.deep_stringify_keys(hash)
      end
    end

    class CollectionManager < Manager
      def define_accessors!
      end

      def find_or_create(options)
        search(unique_conditions(options)).first || create(options)
      end

      def create(data)
        # TODO: include the data from parent
        raise 'not implemented'
      end

      def search(conditions)
        resource.action(:index).call(search_options(conditions))['results'].map do |result|
          build_member(result)
        end
      end

      def build_member(data)
        Member.new(api, resource, self, data)
      end

      # @return [Array<Array<String>>] - various combinations of
      #   params that uniquely identify the resource
      def unique_keys
        [%w[name]]
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

      # Produces search options for the index action based on the conditions
      #
      # @param conditions [Hash] - key-value conditions to produce the search query
      # @return [Hash] - search params to be setn to the index action.
      def search_options(conditions)
        query = conditions.map do |(key, value)|
           "#{key} = \"#{value}\""
        end.join(' AND ')
        { :search => query }
      end
    end

    class MemberManager < Manager
      def save
        raise NotImplementedError
      end

      def define_accessors!
        data.each_key do |key|
          define_model_method(key) { self[key] }
          define_model_method("#{key}=") { |value| self[key] = value }
        end
      end
    end

    class AppManager < Manager
      def define_accessors!
        define_model_method(:organizations) do
          Collection.new(model_manager.api, model_manager.api.resource(:organizations))
        end
      end
    end
  end
end
