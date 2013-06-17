require "docker/model"

module Docker
  class ImageSummary < Model
    map_attribute :id, :id
    map_attribute :tags, :tags
    map_attribute :created, :created

    def created_at
      Time.at(created)
    end

    def short_id
      id[0,6]
    end
  end
end
