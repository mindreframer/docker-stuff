require "docker/model"

module Docker
  class ImageHistory
    class Item < Model
      map_attribute "Id", :id
      map_attribute "CreatedBy", :created_by

      def created_at
        Time.at(attributes["Created"])
      end
    end

    attr_reader :raw_run_list
    def initialize(raw_run_list)
      @raw_run_list = raw_run_list
    end

    def run_list
      @run_list ||= raw_run_list.map do |att|
        Item.new(att)
      end
    end
  end
end
