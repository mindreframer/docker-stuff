require "docker/model"

module Docker
  class Container < Model
    map_attribute "ID", :id
    map_attribute "Image", :image
    map_attribute "NetworkSettings", :network_settings

    def ip
      network_settings["IPAddress"] if network_settings
    end

    def env
      return {} unless config["Env"]
      Hash[config["Env"].map { |e| e.split("=") }]
    end

    def pid
      state["Pid"]
    end

    def started_at
      Time.parse(state["StartedAt"]) if state["StartedAt"]
    end

    def state
      attributes["State"] || {}
    end

    def config
      attributes["Config"] || {}
    end

    def created_at
      Time.parse(attributes["Created"])
    end
  end
end
