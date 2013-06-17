$:.push(File.expand_path("../../", __FILE__))
require "docker/api/client"
require "sinatra"
require "slim"
require "faraday"
require "open3"
require "multi_json"
require "logger"

class App < Sinatra::Application
  set :slim, layout: :application

  get "/" do
    redirect "/images/graph"
  end

  get "/containers/:id" do |id|
    rescue_not_found do
      slim :container, locals: { container: client.get_container(id) }
    end
  end

  get "/containers" do
    slim :containers, locals: { containers: client.containers }
  end

  get "/images/graph" do
    slim :images_graph
  end

  get "/images/:id" do |id|
    rescue_not_found do
      image = client.get_image(id) 
      history = client.get_image_history(id)
      slim :image, locals: { image: image, history: history }
    end
  end

  get "/images" do
    slim :images, locals: { images: client.images }
  end

  get "/images.dot" do
    url = URI(request.url)
    url = "#{url.scheme}://#{url.host}:#{url.port}"
    graph = client.images_tree.to_digraph(url)
    content_type "text/plain"
    graph
  end

  get "/images.:format" do
    url = URI(request.url)
    url = "#{url.scheme}://#{url.host}:#{url.port}"
    graph = client.images_tree.to_digraph(url)

    if params[:format] == "svg"
      content_type "image/svg+xml"
    else
      content_type "application/#{params[:format]}"
    end
    format = params[:format] || "pdf"
    type = params[:type] || "dot"
    stdout, status = Open3.capture2("#{type} -T #{format}", stdin_data: graph)
    stdout
  end

  delete "/images/:id" do |id|
    client.delete_image(id)
    redirect "/"
  end

  private

  def rescue_not_found
    yield
  rescue
    not_found
  end

  def not_found
    status "404"
    slim :not_found
  end

  def link_to_image(image)
    %(<a href="/images/#{image.id}">#{image.id[0,8]}</a>)
  end

  def client
    @client ||= Docker::Api::Client.new(docker_host)
  end

  def docker_host
    ENV["DOCKER_HOST"] || "http://127.0.0.1:4243"
  end
end
