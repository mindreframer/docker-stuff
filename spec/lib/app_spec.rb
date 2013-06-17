require "spec_helper"
require "rack/test"
require "app"

describe "The App" do
  include Rack::Test::Methods

  def app
    @app = App
  end

  it "GET /" do
    get "/"
    last_response.should be_redirect
  end

  it "GET /images/graph" do
    get "/images/graph"
    last_response.should be_ok
  end

  it "GET /images/8a3065e5b690ea4a27aa3efb9af8e2e40a210af81621cb2bcd10ff9d27b0dc9f" do
    get "/images/8a3065e5b690ea4a27aa3efb9af8e2e40a210af81621cb2bcd10ff9d27b0dc9f"
    last_response.should be_ok
  end

  it "GET /containers" do
    get "/containers"
    last_response.should be_ok
  end

  it "GET /containers/12345" do
    get "/containers/12345"
    last_response.should be_not_found
  end

  it "GET /images/12345" do
    get "/images/12345"
    last_response.should be_not_found
  end
end
