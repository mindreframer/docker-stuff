docker_image "ubuntu" do
  action :delete
end

docker_image "ubuntu" do
  tag "precise"
  action :add
end
