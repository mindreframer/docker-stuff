require "multi_json"
require "docker/container_summary"
require "docker/container"
require "docker/image"
require "docker/image_summary"
require "docker/image_history"
require "docker/images_tree"
require "net/http"

module Docker
  module Api
    class Client
      attr_reader :uri

      def initialize(uri)
        @uri = uri.gsub(/[\/]+$/, "")
      end

      def containers
        rsp = get("/containers/json?all=true")
        MultiJson.load(rsp).map do |json|
          ContainerSummary.new(json)
        end
      end

      def images_tree
        ImagesTree.new(full_images)
      end

      def full_images
        images_hash.map do |(id, created), tags|
          image = get_image(id)
          image.tags = tags
          image
        end
      end

      def images
        images_hash.map do |(id, created), tags|
          ImageSummary.new(id: id, tags: tags.reject { |t| t == "" }, created: created)
        end
      end

      def images_hash
        rsp = get("/images/json?all=true")
        out = {}
        MultiJson.load(rsp).map do |json|
          key = [json["Id"], json["Created"]]
          (out[key] ||= []) << [json["Repository"], json["Tag"]].compact.join(":")
        end
        out
      end

      def delete_image(id)
        uri = URI("#{@uri}/images/#{id}")
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Delete.new(uri.request_uri)
          response = http.request(request)
        end
      end

      def get_image(id)
        rsp = get("/images/#{id}/json")
        Image.new(MultiJson.load(rsp))
      end

      def get_container(id)
        rsp = get("/containers/#{id}/json")
        Container.new(MultiJson.load(rsp))
      end

      def get_image_history(id)
        rsp = get("/images/#{id}/history")
        ImageHistory.new(MultiJson.load(rsp))
      end

      def get(path)
        uri = URI("#{@uri}#{path}")
        rsp = http.request(uri)
        raise "not found" if rsp.code == "404"
        rsp.body
      end

      def http
        require "net/http/persistent"
        @http ||= Net::HTTP::Persistent.new("docker")
      end
    end
  end
end
