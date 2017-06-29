#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2015 GitLab B.V.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
mattermost_user = node['gitlab']['mattermost']['username']
mattermost_group = node['gitlab']['mattermost']['group']
mattermost_uid = node['gitlab']['mattermost']['uid']
mattermost_gid = node['gitlab']['mattermost']['gid']
mattermost_home = node['gitlab']['mattermost']['home']
mattermost_log_dir = node['gitlab']['mattermost']['log_file_directory']
mattermost_storage_directory = node['gitlab']['mattermost']['file_directory']
postgresql_socket_dir = node['gitlab']['postgresql']['unix_socket_directory']
pg_port = node['gitlab']['postgresql']['port']
pg_user = node['gitlab']['postgresql']['username']
config_file_path = File.join(mattermost_home, "config.json")
mattermost_log_file = File.join(mattermost_log_dir, 'mattermost.log')

###
# Create group and user that will be running mattermost
###
account "Mattermost user and group" do
  username mattermost_user
  uid mattermost_uid
  ugid mattermost_group
  groupname mattermost_group
  gid mattermost_gid
  shell '/bin/sh'
  home mattermost_home
  manage node['gitlab']['manage-accounts']['enable']
end

###
# Create required directories
###

[
  mattermost_home,
  mattermost_log_dir,
  mattermost_storage_directory
].compact.each do |dir|
  directory dir do
    owner mattermost_user
    recursive true
  end
end

# Fix an issue where GitLab 8.9 would create the log file as root on error
file mattermost_log_file do
  owner mattermost_user
  only_if { File.exist? mattermost_log_file }
end

###
# Create the database users, create the database we need, and grant them
# privileges.
###

pg_helper = PgHelper.new(node)
bin_dir = "/opt/gitlab/embedded/bin"

mysql_adapter = node['gitlab']['mattermost']['sql_driver_name'] == 'mysql' ? true : false
db_name = node['gitlab']['mattermost']['database_name']
sql_user = node['gitlab']['postgresql']['sql_mattermost_user']

postgresql_user sql_user do
  action :create
  not_if { mysql_adapter }
end

execute "create #{db_name} database" do
  command "#{bin_dir}/createdb --port #{pg_port} -h #{postgresql_socket_dir} -O #{sql_user} #{db_name}"
  user pg_user
  not_if { mysql_adapter || !pg_helper.is_running? || pg_helper.database_exists?(db_name) }
  retries 30
end

###
# Populate mattermost configuration options
###
unless node['gitlab']['mattermost']['gitlab_enable']
  ruby_block "authorize mattermost with gitlab" do
    block do
      MattermostHelper.authorize_with_gitlab(Gitlab['external_url'])
    end
    # Try connecting to GitLab only if it is enabled
    only_if { node['gitlab']['gitlab-rails']['enable'] && pg_helper.is_running? && pg_helper.database_exists?(node['gitlab']['gitlab-rails']['db_database']) }
  end
end

ruby_block "populate mattermost configuration options" do
  block do
    node.consume_attributes(Gitlab.generate_hash)
  end
end

template config_file_path do
  source "config.json.erb"
  owner mattermost_user
  variables lazy { node['gitlab']['mattermost'].to_hash.merge(node['gitlab']['postgresql']).to_hash }
  mode "0644"
  notifies :restart, "service[mattermost]"
end

###
# Mattermost control service
###

runit_service "mattermost" do
  options({
    :log_directory => mattermost_log_dir
  }.merge(params))
  log_options node['gitlab']['logging'].to_hash.merge(node['gitlab']['mattermost'].to_hash)
end
