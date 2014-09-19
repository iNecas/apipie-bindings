module ApipieBindings
  module Model
    # Defines methods to be used in the IRB console for describing the models
    module Helper

      def show(model)
        puts Renderer.new(model).render
      end

      class Renderer
        attr_reader :model, :out

        def initialize(model)
          raise 'Unexpected object, expected model' unless model.is_a? Model::Base
          @model = model
          @out   = ""
        end

        def render
          reset!
          add_name
          add_blank_line
          add_params
          out
        end

        def add_name
          add model.inspect
        end

        def add_params
          add_title "Params:"
          param_definitions = model._manager.params_from_docs.map do |param|
            name_with_flags = "#{ param.name }#{ param.required? ? "*" : "" }:"
            [name_with_flags, model[param.name].inspect]
          end
          add_definitions(param_definitions)
        end

        def reset!
          @out = ""
        end

        def add_blank_line
          add "\n"
        end

        def add_title(text)
          add text
          add "-" * text.size
        end

        def add_definitions(param_definitions)
          max_width = param_definitions.map { |key, value| key.size }.max
          param_definitions.each { |left, right| add "%-#{max_width}s %s" % [left, right] }
        end

        def add(line)
          @out << line << "\n"
        end
      end
    end
  end
end
