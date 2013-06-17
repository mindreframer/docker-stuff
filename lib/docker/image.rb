require "docker/model"

module Docker
  class Image < Model
    attr_accessor :tags

    map_attribute "id", :id
    map_attribute "parent", :parent
    map_attribute "container", :container
    map_attribute :summary, :summary


    def short_id
      id[0,6]
    end

    def env
      parse_env(config["Env"])
    end

    def config
      attributes["config"] || {}
    end

    def created_at
      Time.parse(attributes["created"])
    end

    def tag
      summary.tag if summary
    end

    def repository
      summary.repository if summary
    end
  end
end
