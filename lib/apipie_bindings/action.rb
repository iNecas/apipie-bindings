require 'set'

module ApipieBindings

  class Action

    attr_reader :name

    def initialize(resource, name, api)
      @resource = resource
      @name = name.to_sym
      @api = api
    end

    def call(params={}, headers={}, options={})
      @api.call(@resource, @name, params, headers, options)
    end

    def apidoc
      methods = @api.apidoc[:docs][:resources][@resource][:methods].select do |action|
        action[:name].to_sym == @name
      end
      methods.first
    end

    def routes
      apidoc[:apis].map do |api|
        ApipieBindings::Route.new(
          api[:api_url], api[:http_method], api[:short_description])
      end
    end

    def params
      if apidoc
        apidoc[:params].map do |param|
          ApipieBindings::Param.new(param)
        end
      else
        []
      end
    end

    def all_params
      present_params = Set.new
      (params + params_from_routes).select do |param|
        unless present_params.include?(param.name.to_s)
          present_params << param.name.to_s
        end
      end
    end

    def params_from_routes
      self.routes.inject([]) do |params, route|
        params.concat(route.params_in_path.map do |param_name|
                        Param.new(:name          => param_name,
                                  :description   => '',
                                  :expected_type => 'string',
                                  :required      => true)
                      end)
      end
    end

    def examples
      apidoc[:examples].map do |example|
        ApipieBindings::Example.parse(example)
      end
    end

    def find_route(params={})
      sorted_routes = routes.sort_by { |r| [-1 * r.params_in_path.count, r.path] }

      suitable_route = sorted_routes.find do |route|
        route.params_in_path.all? { |path_param| params.keys.map(&:to_s).include?(path_param) }
      end

      suitable_route ||= sorted_routes.last
      return suitable_route
    end

    def validate!(params)
      # return unless params.is_a?(Hash)

      # invalid_keys = params.keys.map(&:to_s) - (rules.is_a?(Hash) ? rules.keys : rules)
      # raise ArgumentError, "Invalid keys: #{invalid_keys.join(", ")}" unless invalid_keys.empty?

      # if rules.is_a? Hash
      #   rules.each do |key, sub_keys|
      #     validate_params!(params[key], sub_keys) if params[key]
      #   end
      # end
    end

    def to_s
      "<Action :#{@name}>"
    end

    def inspect
      to_s
    end

  end
end
