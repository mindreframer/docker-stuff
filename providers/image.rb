action :add do
  pull_command = "docker pull"
  pull_command << " -registry=#{new_resource.registry}" if new_resource.registry
  pull_command << " -t=#{new_resource.tag}" if new_resource.tag
  pull_command << " #{new_resource.name}"

  execute "add image" do
    command pull_command
    action :run
  end
end

action :delete do
  execute "remove image" do
    command "docker rmimage #{new_resource.name}"
    action :run
  end
end
