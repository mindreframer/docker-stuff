require "faraday"
require "multi_json"

class Docker
  attr_reader :host, :port

  class Image
    def initialize(atts)
      @atts = atts
    end

    def id
      @atts["Id"] || @atts["id"]
    end

    def tag
      @atts["Tag"]
    end

    def parent
      @atts["parent"]
    end
  end

  def initialize(host, port = 4243)
    @host = host
    @port = port
  end

  def get_leaves
    rsp = Faraday.get("#{url}/images/json?all=1").body
    images = MultiJson.load(rsp).map { |img| Image.new(img) }
    tree = {}
    ids = Set.new

    images.each do |img|
      full_img = Image.new(MultiJson.load(Faraday.get("http://#{host}:#{port}/images/#{img.id}/json").body))
      ids << full_img.id unless img.tag
      if full_img.parent
        tree[full_img.parent] ||= []
        tree[full_img.parent] << full_img
      end
    end
    parents = tree.keys
    ids - parents
  end

  def build(docerfile)
    rsp = Faraday.post("#{url}/build", body: docerfile)
    p rsp
    headers.body
  end

  def url
    "http://#{host}:#{port}"
  end
end

docker = Docker.new("192.168.34.12", 4243)
docker.build "FROM ubuntu\nRUN apt-get install pv -y"
p docker.get_leaves

exit


require "em-http-request"
EventMachine.run do
  http = EventMachine::HttpRequest.new('http://www.heise.de').get
  http.stream do |env|
    p env.count
  end
  p :danach
end
