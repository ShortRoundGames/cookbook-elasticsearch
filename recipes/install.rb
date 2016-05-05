#-*- encoding : utf-8 -*-
elasticsearch = "elasticsearch-#{node[:elasticsearch][:version]}"
include_recipe "elasticsearch::packages"

# Create user and group
group node[:elasticsearch][:user] do
  action :create
end

user node[:elasticsearch][:user] do
  comment "ElasticSearch User"
  home    "/home/elasticsearch"
  shell   "/bin/bash"
  gid     node[:elasticsearch][:user]
  supports :manage_home => false
  action  :create
end

# Install ElasticSearch
script "install_elasticsearch" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
    wget "#{node[:elasticsearch][:download_url]}"
    tar xvzf #{node[:elasticsearch][:filename]} -C #{node[:elasticsearch][:dir]}
    ln -s "#{node[:elasticsearch][:home_dir]}-#{node[:elasticsearch][:version]}" #{node[:elasticsearch][:home_dir]}
  EOH
  not_if "ls #{node[:elasticsearch][:home_dir]}-#{node[:elasticsearch][:version]}"
end

# Create Symlink
link "#{node[:elasticsearch][:home_dir]}" do
  to "#{node[:elasticsearch][:home_dir]}-#{node[:elasticsearch][:version]}"
end

# Plugins don't need to be installed on ES 1.4.0+
#if !!node[:elasticsearch][:basic_auth]
#  directory node[:elasticsearch][:path][:plugins] do
#    owner node[:elasticsearch][:user]
#    group node[:elasticsearch][:user]
#  end
#
#  cookbook_file "#{node[:elasticsearch][:path][:plugins]}/elasticsearch-http-basic-1.3.2.jar" do
#    source "elasticsearch-http-basic-1.3.2.jar"
#    owner node[:elasticsearch][:user]
#    group node[:elasticsearch][:user]
#    mode 0755
#    backup false
#    action :create_if_missing
#  end
#
#  execute "unzip elasticsearch jar" do
#    command "unzip #{node[:elasticsearch][:path][:plugins]}/elasticsearch-http-basic-1.3.2.jar -d #{node[:elasticsearch][:path][:plugins]}/http-basic"
#    user node[:elasticsearch][:user]
#    not_if "ls #{node[:elasticsearch][:path][:plugins]}/http-basic"
#  end
#end

# Install AWS plugin (for snapshots)
bash "install_aws_plugin" do
  user "root"
  cwd "#{node[:elasticsearch][:home_dir]}"
  code <<-EOH
    bin/plugin remove cloud-aws
    bin/plugin install cloud-aws
  EOH
end

# Install Knapsack plugin (for importing/exporting compressed chunks of data)
bash "install_knapsack_plugin" do
  user "root"
  cwd "#{node[:elasticsearch][:home_dir]}"
  code <<-EOH
    bin/plugin remove knapsack
    bin/plugin install http://xbib.org/repository/org/xbib/elasticsearch/plugin/elasticsearch-knapsack/#{node[:elasticsearch][:knapsack_plugin][:version]}/elasticsearch-knapsack-#{node[:elasticsearch][:knapsack_plugin][:version]}-plugin.zip
  EOH
end

# Create directory to export the knapsack archives to
directory "#{node['elasticsearch']['dir']}/knapsacks" do
  owner node[:elasticsearch][:user]
  group node[:elasticsearch][:user]
end

# We need to install a pill so we can run through bluepill
template "#{node['elasticsearch']['dir']}/elasticsearch.pill" do
  source 'elasticsearch.pill.erb'
  mode   '0644'
  owner  'root'
end

# Create scripts directory
directory node[:elasticsearch][:path][:conf]/scripts do
  owner 'root'
end
