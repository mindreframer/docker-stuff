module Docker
  class Model
    class << self
      def map_attribute(from, to)
        define_method(to) do
          attributes[from]
        end
      end
    end

    attr_reader :attributes

    def initialize(attributes)
      @attributes = attributes
    end

    def parse_env(the_env)
      return {} unless the_env
      Hash[the_env.map { |e| e.split("=") }]
    end
  end
end
