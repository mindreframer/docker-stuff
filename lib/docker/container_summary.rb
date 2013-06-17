require "docker/model"

module Docker
  class ContainerSummary < Model
    map_attribute "Id", :id
    map_attribute "Image", :image
    map_attribute "Command", :command

    def created_at
      Time.at(attributes["Created"])
    end

    def short_id
      id[0,8]
    end

    def ports
      attributes["Ports"].split("")
    end

    def status
      attributes["Status"]
    end
  end
end
