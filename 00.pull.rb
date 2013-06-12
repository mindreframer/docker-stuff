#!/usr/bin/env ruby
##### inspired by:
## http://code.dimilow.com/git-subtree-notes-and-workflows/

PROJECTS = %w(
https://github.com/crosbymichael/dockerui.git
https://github.com/dotcloud/docker.git
https://github.com/dotcloud/docker-registry.git
https://github.com/dotcloud/dockerlite.git
https://github.com/dotcloud/openstack-docker.git
https://github.com/dreid/docker-cookbook.git
https://github.com/fsouza/go-dockerclient.git
https://github.com/globocom/docker-cluster.git
https://github.com/globocom/tsuru.git
https://github.com/progrium/buildstep.git
https://github.com/progrium/dokku.git
https://github.com/portertech/kitchen-docker.git
).sort_by{|x| x.downcase}

def remote_name(git_url)
  "remote_#{git_url.split("/").last[0..-5]}"
end

def name(git_url)
  # owner = (git_url.split("/")[-2])
  # repo = git_url.split("/").last[0..-5]
  # owner, repo = [owner, repo].map{|x| x.downcase}
  # "#{owner}__#{repo}"
  path = git_url.split("//").last
  path = path.gsub(/\.git$/, "")
end

def add_remote(git_url)
  cmd = "git remote add #{remote_name(git_url)} #{git_url}"
  execute(cmd)
end

def add_project(git_url)
ensure_folder_exists(git_url)
  cmd =  "git subtree add --prefix=#{name(git_url)} --squash #{git_url} master"
  execute(cmd)
end

def ensure_folder_exists(git_url)
  cmd =  "mkdir -p #{File.dirname(name(git_url))}"
  execute(cmd)
end

def update_project(git_url)
  cmd = "git subtree pull --prefix #{name(git_url)} --squash #{git_url} master"
  execute(cmd)
end

def handle_project(git_url)
  if File.exist?(name(git_url))
    update_project(git_url)
  else
    add_remote(git_url)
    add_project(git_url)
  end
end

def execute(cmd)
  `#{cmd}`
  # puts cmd
end

### update projects
PROJECTS.each do |p| handle_project(p) end
